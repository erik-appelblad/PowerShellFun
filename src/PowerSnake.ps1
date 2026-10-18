Clear-Host

enum Direction {
    Up
    Left
    Down
    Right
}

class Cell {
    [int]$X
    [int]$Y

    Cell([int]$x, [int]$y) {
        $this.X = $x
        $this.Y = $y
    }
}

class Snake {
    [System.Collections.Generic.LinkedList[Cell]]$Cells
    [Cell]$Head
    [Direction]$Heading

    Snake([int]$x, [int]$y, [Direction]$heading) {
        $this.Head = [Cell]::new($x, $y)
        $this.Cells = [System.Collections.Generic.LinkedList[Cell]]::new()
        $this.Heading = $heading
    }
}

$cols = 25
$rows = 20
$headX = 20
$headY = 10
$snake = [Snake]::new($headX, $headY, [Direction]::Left)
$score = 0
$gameOver = $false
$hasWon = $false

function PlaceFruit {
    $availableCells = [System.Collections.Generic.List[Cell]]::new()

    for ($y = 1; $y -lt ($script:rows - 1); $y++) {
        for ($x = 1; $x -lt ($script:cols - 1); $x++) {
            $occupied = $x -eq $script:snake.Head.X -and $y -eq $script:snake.Head.Y
            foreach ($cell in $script:snake.Cells) {
                if ($x -eq $cell.X -and $y -eq $cell.Y) {
                    $occupied = $true
                    break
                }
            }

            if (-not $occupied) {
                $availableCells.Add([Cell]::new($x, $y))
            }
        }
    }

    if ($availableCells.Count -eq 0) {
        return $null
    }

    return Get-Random -InputObject $availableCells
}

function Draw {
    [Console]::SetCursorPosition(0, 0)

    for ($y = 0; $y -lt $script:rows; $y++) {
        $lineArr = [char[]]::new($script:cols)
        for ($x = 0; $x -lt $script:cols; $x++) {
            if ($x -eq 0 -or $x -eq $script:cols - 1 -or $y -eq 0 -or $y -eq $script:rows - 1) {
                $lineArr[$x] = '#'
            } elseif ($x -eq $script:snake.Head.X -and $y -eq $script:snake.Head.Y) {
                $lineArr[$x] = '$'
            } elseif ($null -ne $script:fruit -and $x -eq $script:fruit.X -and $y -eq $script:fruit.Y) {
                $lineArr[$x] = '@'
            } else {
                $lineArr[$x] = '.'
                foreach ($cell in $script:snake.Cells) {
                    if ($x -eq $cell.X -and $y -eq $cell.Y) {
                        $lineArr[$x] = '¤'
                        break
                    }
                }
            }
        }
        Write-Host $lineArr
    }
}

$fruit = PlaceFruit
[Console]::CursorVisible = $false

while (-not $gameOver) {
    while ([Console]::KeyAvailable) {

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            'UpArrow' {
                if ($snake.Heading -ne [Direction]::Down) {
                    $snake.Heading = [Direction]::Up
                }
            }
            'LeftArrow' {
                if ($snake.Heading -ne [Direction]::Right) {
                    $snake.Heading = [Direction]::Left
                }
            }
            'DownArrow' {
                if ($snake.Heading -ne [Direction]::Up) {
                    $snake.Heading = [Direction]::Down
                }
            }
            'RightArrow' {
                if ($snake.Heading -ne [Direction]::Left) {
                    $snake.Heading = [Direction]::Right
                }
            }
            'Escape' {
                [Console]::CursorVisible = $true
                Clear-Host
                return
              }
            Default {}
        }
    }
    
    $nextX = $snake.Head.X
    $nextY = $snake.Head.Y
    switch ($snake.Heading) {
        ([Direction]::Up) { $nextY-- }
        ([Direction]::Left) { $nextX-- }
        ([Direction]::Down) { $nextY++ }
        ([Direction]::Right) { $nextX++ }
    }

    if ($nextX -eq 0 -or $nextX -eq $cols - 1 -or $nextY -eq 0 -or $nextY -eq $rows - 1) {
        $gameOver = $true
        break
    }

    $eatingFruit = $null -ne $fruit-and $nextX -eq $fruit.X -and $nextY -eq $fruit.Y
    $hitBody = $false
    foreach ($cell in $snake.Cells) {
        $isMovingTail = -not $eatingFruit -and
            $null -ne $snake.Cells.Last -and
            [object]::ReferenceEquals($cell, $snake.Cells.Last.Value)
        if ($nextX -eq $cell.X -and $nextY -eq $cell.Y -and -not $isMovingTail) {
            $hitBody = $true
            break
        }
    }

    if ($hitBody) {
        $gameOver = $true
        break
    }

    [void]$snake.Cells.AddFirst($snake.Head)
    $snake.Head = [Cell]::new($nextX, $nextY)
    if ($eatingFruit) {
        $score++
        $fruit = PlaceFruit
        if ($null -eq $fruit) {
            $hasWon = $true
            break
        }
    } else {
        $snake.Cells.RemoveLast()
    }

    Draw

    Write-Host ""
    Write-Host "Score: $score"
    Write-Host "ESC = Quit"
    
    Start-Sleep -Milliseconds (120 - $score)
} 

Draw
if ($hasWon) {
    Write-Host "You win!"
} else {
    Write-Host "You lost!"
}
Write-Host "Score: $score"
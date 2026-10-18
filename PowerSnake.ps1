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

$heading = [Direction]::Left
$cols = 30
$rows = 25
$headX = 15
$headY = 15
$snake = [Snake]::new($headX, $headY, $heading)

function PlaceFruit {
    while ($true) {
        $x = Get-Random -Minimum 1 -Maximum ($cols - 1)
        $y = Get-Random -Minimum 1 -Maximum ($rows - 1)

        if ($x -ne $script:snake.X -or $y -ne $script:snake.Y) {
            return [Cell]::new($x, $y)
        }
    }
}

function Draw {
    [Console]::SetCursorPosition(0, 0)

    for ($y = 0; $y -lt $rows; $y++) {
        $lineArr = [char[]]::new($cols)
        for ($x = 0; $x -lt $cols; $x++) {
            if ($x -eq 0 -or $x -eq $cols-1 -or $y -eq 0 -or $y -eq $rows - 1) {
                $lineArr[$x] = '#'
            } elseif ($x -eq $headX -and $y -eq $headY) {
                $lineArr[$x] = '$'
            } elseif ($x -eq $fruit.X -and $y -eq $fruit.Y) {
                $lineArr[$x] = '@'
            } else {
                $lineArr[$x] = '.'
            }
        }
        Write-Host ($lineArr)
    }
}

$fruit = PlaceFruit
[Console]::CursorVisible = $false

while ($true) {
    #Input
    while ([Console]::KeyAvailable) {

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            'UpArrow' {
                if ($heading -ne [Direction]::Down) {
                    $heading = [Direction]::Up
                }
            }
            'LeftArrow' {
                if ($heading -ne [Direction]::Right) {
                    $heading = [Direction]::Left
                }
            }
            'DownArrow' {
                if ($heading -ne [Direction]::Up) {
                    $heading = [Direction]::Down
                }
            }
            'RightArrow' {
                if ($heading -ne [Direction]::Left) {
                    $heading = [Direction]::Right
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
    
    # Collision
    if ($headX -eq $fruit.X -and $headY -eq $fruit.Y) {

        $score++
        $fruit = PlaceFruit
    }

    if ($headX -eq 0 -or $headX -eq $cols-1 -or $headY -eq 0 -or $headY -eq $rows-1) {
        break
    }

    if ($heading -eq [Direction]::Up) {
        $headY -= 1
    }
    if ($heading -eq [Direction]::Left) {
        $headX -= 1
    }
    if ($heading -eq [Direction]::Down) {
        $headY += 1
    }
    if ($heading -eq [Direction]::Right) {
        $headX += 1
    }

    Draw


    Write-Host ""
    Write-Host "Score: $score"
    Write-Host "ESC = Quit"
    
    Start-Sleep -Milliseconds 100
} 

Draw
Write-Host "You lost!"
Write-Host "Score: $score"
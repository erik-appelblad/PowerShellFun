param (
    [int]$noOfCols,
    [int]$noOfRows
)

Clear-Host

[int]$cols
[int]$rows
[int]$score
[int]$maxSleepTime
[int]$minSleepTime
[bool]$gameOver
[bool]$hasWon
[bool]$keepPlaying = $true
[datetime]$startTime = Get-Date
[Cell]$fruit

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
    [System.Collections.Generic.LinkedList[Cell]]$Body
    [Cell]$Head
    [Direction]$CurrentDirection

    Snake([int]$x, [int]$y, [Direction]$heading) {
        $this.Head = [Cell]::new($x, $y)
        $this.Body = [System.Collections.Generic.LinkedList[Cell]]::new()
        $this.CurrentDirection = $heading
    }
}

function Init {
    if ($script:noOfCols -gt 5) {
        $script:cols = $script:noOfCols
    } else {
        $script:cols = 20
    }

    if ($script:noOfRows -gt 5) {
        $script:rows = $script:noOfRows
    } else {
        $script:rows = 20
    }

    $script:snake = [Snake]::new(1, $script:rows / 2, [Direction]::Right)
    $script:score = 0
    $script:maxSleepTime = 120
    $script:minSleepTime = 20
    $script:gameOver = $false
    $script:hasWon = $false
    $script:startTime = Get-Date
}

function PlaceFruit {
    $availableCells = [System.Collections.Generic.List[Cell]]::new()

    for ($y = 1; $y -lt ($rows - 1); $y++) {
        for ($x = 1; $x -lt ($cols - 1); $x++) {
            $occupied = $x -eq $snake.Head.X -and $y -eq $snake.Head.Y
            if (-not $occupied) {
                foreach ($cell in $snake.Body) {
                    if ($x -eq $cell.X -and $y -eq $cell.Y) {
                        $occupied = $true
                        break
                    }
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

    for ($y = 0; $y -lt $rows; $y++) {
        $lineArr = [char[]]::new($cols)
        for ($x = 0; $x -lt $cols; $x++) {
            if ($x -eq 0 -or $x -eq $cols - 1 -or $y -eq 0 -or $y -eq $rows - 1) {
                $lineArr[$x] = '#'
            } elseif ($x -eq $snake.Head.X -and $y -eq $snake.Head.Y) {
                $lineArr[$x] = '$'
            } elseif ($null -ne $fruit -and $x -eq $fruit.X -and $y -eq $fruit.Y) {
                $lineArr[$x] = '@'
            } else {
                $lineArr[$x] = '.'
                foreach ($cell in $snake.Body) {
                    if ($x -eq $cell.X -and $y -eq $cell.Y) {
                        $lineArr[$x] = 'o'
                        break
                    }
                }
            }
        }

        $currentColor = $null

        foreach ($char in $lineArr) {
            $nextColor = switch ($char) {
                '#' { 'Blue' }
                '.' { 'Cyan' }
                '@' { 'Red' }
                '$' { 'Green' }
                'o' { 'Green' }
                Default { 'Green' }
            }

            if ($nextColor -ne $currentColor) {
                [Console]::ForegroundColor = $nextColor
                $currentColor = $nextColor
            }

            [Console]::Write($char)
            [Console]::Write(' ')
        }
        [Console]::ResetColor()
        [Console]::WriteLine()
    }
}

function Run {
    $script:fruit = PlaceFruit
    [Console]::CursorVisible = $false

    while (-not $gameOver) {
        while ([Console]::KeyAvailable) {

            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                'UpArrow' {
                    if ($snake.CurrentDirection -ne [Direction]::Down) {
                        $snake.CurrentDirection = [Direction]::Up
                    }
                }
                'LeftArrow' {
                    if ($snake.CurrentDirection -ne [Direction]::Right) {
                        $snake.CurrentDirection = [Direction]::Left
                    }
                }
                'DownArrow' {
                    if ($snake.CurrentDirection -ne [Direction]::Up) {
                        $snake.CurrentDirection = [Direction]::Down
                    }
                }
                'RightArrow' {
                    if ($snake.CurrentDirection -ne [Direction]::Left) {
                        $snake.CurrentDirection = [Direction]::Right
                    }
                }
                'Escape' {
                    [Console]::CursorVisible = $true
                    Clear-Host
                    $script:keepPlaying = $false
                    return
                }
                Default {}
            }
        }
        
        $nextX = $snake.Head.X
        $nextY = $snake.Head.Y

        switch ($snake.CurrentDirection) {
            ([Direction]::Up) { $nextY-- }
            ([Direction]::Left) { $nextX-- }
            ([Direction]::Down) { $nextY++ }
            ([Direction]::Right) { $nextX++ }
        }

        if ($nextX -eq 0 -or $nextX -eq $cols - 1 -or $nextY -eq 0 -or $nextY -eq $rows - 1) {
            $gameOver = $true
            break
        }

        $isEating = $null -ne $fruit-and $nextX -eq $fruit.X -and $nextY -eq $fruit.Y
        $isBodyHit = $false

        foreach ($cell in $snake.Body) {
            $isMovingTail = -not $isEating -and
                $null -ne $snake.Body.Last -and
                $cell -eq $snake.Body.Last.Value
            if ($nextX -eq $cell.X -and $nextY -eq $cell.Y -and -not $isMovingTail) {
                $isBodyHit = $true
                break
            }
        }

        if ($isBodyHit) {
            $gameOver = $true
            break
        }

        [void]$snake.Body.AddFirst($snake.Head)
        $snake.Head = [Cell]::new($nextX, $nextY)

        if ($isEating) {
            $script:score++
            $script:fruit = PlaceFruit

            if ($null -eq $fruit) {
                $script:hasWon = $true
                break
            }
        } else {
            $snake.Body.RemoveLast()
        }

        Draw

        Write-Host ""
        Write-Host "Score: $score"
        Write-Host "ESC = Quit"
        
        $sleepDuration = $maxSleepTime - $score
        Start-Sleep -Milliseconds ([Math]::Clamp($sleepDuration, $minSleepTime, $maxSleepTime))
    }
}

while ($keepPlaying) {
    Init
    Run
    Draw
    
    if ($hasWon) {
        Write-Host "You win!" -ForegroundColor Blue
    } else {
        Write-Host "You lost!" -ForegroundColor Red
    }

    Write-Host "Score: $score"
    
    $date = Get-Date
    $time = $date - $startTime
    
    [Console]::CursorVisible = $true
    
    $retry = Read-Host -Prompt "Do you want to try again? [Y|N]"

    if ($retry -eq 'Y') {
        $keepPlaying = $true
        Clear-Host
        continue
    } else {
        $keepPlaying = $false
    }
    
    $name = Read-Host -Prompt "What's your name? [Q to quit]"
    
    if ($name -eq 'Q') {
        $keepPlaying = $false
        Clear-Host
        break
    }
    
    $filename = "highscores.csv"
    
    Write-Host "Well done $name, you got $score fruits!"
    $save = Read-Host -Prompt "Add score to highscore list? [Y|N|Q]"
    
    if ($save -eq 'Y') {
        if (-not (Test-Path $filename)) {
            Set-Content -path highscores.csv "Date,Name,Score,Playtime"
        }
        Add-Content $filename -value "$date,$name,$score,$time"
    } elseif ($save -eq 'Q') {
        $keepPlaying = $false
        Clear-Host
        break
    }
    
    $view = Read-Host -Prompt "View top 5 highscores? [Y|N|Q]"
    
    if ((Test-Path $filename) -and $view -eq 'Y') {
        Import-Csv -Path $filename
        | Select-Object -Property Name, @{ Name = 'Score'; Expression = { [int]$_.Score } }
        | Sort-Object -Property Score -Descending
        | Select-Object -First 5
        | Out-String
        | Write-Host
    } elseif ($view -eq 'Q') {
        $keepPlaying = $false
        Clear-Host
        break
    }
}
# [TankGrid!](https://pedohorse.github.io/tankgrid/)

It's a game that allows you to compete with other players in who can make a better hunter-killer tank drone.

Each player may register and upload one or several programs for in-game tanks.
Once in a while the system will run battles for all possible pairs of programs, 
and you will see the results in the table on the [front page](https://pedohorse.github.io/tankgrid/).

Click on any table cell and open that battle's replay.

## How to write tank programs.

Tank are controlled by python code (currently: python 3.12):
- imports are not allowed
- special tank controlling functions are avialable (see [manual](https://pedohorse.github.io/tankgrid/manual))
- calls to standard print function are displayed as tank's log in the replay, convenient for debugging.

## Note
This is in a very rough alpha stage. Things sorta work, but rough around the edges.

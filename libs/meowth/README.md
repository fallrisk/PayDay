
# Meowth

A library for running a gambling hall where the only game is rolling a single
die.

Based on https://atamis.me/crossgambling/

# Match

A match is a single run of a gambling session. It is a match between the
people gambling (gamblers). When you create a match you must specify the
maximum and minimum roll. Users have to join a match. Users can leave the
match before the gambling begins, known as the "roll phase". You first begin a
match in the "join phase". To add a gambler call `match.AddGambler("gambler
name")`. You can also remove a gambler during the "join phase". To remove a
gambler call `match.RemoveGambler("name")`. Then once you have given everyone
enough time you can start the match with `match.Start()`. At this point you
are in the "roll phase". During the roll phase you must submit every gamblers
roll. Call `match.AddRoll("gambler name", roll)`. If the gambler was not added
during the "join phase" then their roll will be ignored. If the roll is
outside the minimum and maximum roll it is ignored. At anytime during the
"roll phase" you can request a list of gamblers you are still waiting on the
roll for with `match.GetWaitingList()`. Once all gamblers have submitted their
rolls then you are in the "check phase". 

In the "check phase" the rolls are checked to see if there is a high or low
tie. If there is a high tie then you go to the "high tie phase". You cannot
leave the "high tie phase" until the high tie is resolved or you end the
match. During the "high tie phase" just resubmit rolls for those that tied
using `match.AddRoll("gambler name", roll)`. Submissions for gamblers not in
the high tie are ignored. After the "high tie phase" the code will check to
see if you have a low tie. If you did not have a high tie the code goes
directly to checking for a low tie.

If there is a low tie the code goes into the "low tie phase". You cannot leave
the "low tie phase" until the low tie is reolved or you end the match. During
the "low tie phase" just resubmit rolls for those that tied. Submissions for
gamblers not in the low tie are ignored. Once the "low tie phase" is resolved
then the system goes to the "complete phase". If there was no low tie, then
the system goes straight to the "complete phase".

When you are in any of the phase "high tie", "low tie", or "roll", you can
query whom you are waiting for with `match.GetWaitingList()`.

At anytime you can end the match with `match.End()` if the match is ended it
goes to the "canceled phase". Once the match is in the "complete phase" or
"canceled phase" it cannot be changed. Calling any of the functions that would
move it through phases are ignored.

If you attempt to start the "roll phase" and have less than 2 people joined
the match will not go into the roll phase. The funcion `match.Start()` will
return false. If you have more than 2 people joined and call `match.Start()`
the function will return true and will go to the "roll phase".

## Match Stats

* highRoll: The high gambler's roll.
* highGambler: The gambler who rolled the highest.
* lowRoll: The low gambler's roll.
* lowGambler: The gambler who rolled the lowest.

# Stats

A `stats` object is statistics for a collection of matches. It is a running
statistics class. At the end of each match your match data can be submitted to
a stats object to keep a running total of information across serveral matches.
You should create a stats object before you start your first match. That way
at any point you can get statistics for the matches. The main function is
`GetGamblersSorted`, which returns an array (a table with numerical indices)
of the gambler's sorted from most won (key 1) to most loss (key N).

# Testing

## Windows

[Download Lua 5.1.4](https://sourceforge.net/projects/luabinaries/files/5.1.4/Tools%20Executables/).
I grabbed the archive lua5_1_4_Win64_bin.zip. Then I extracted the archive to
`C:\lua5_1_4_Win64_bin`. So my directory structure looked like
`C:\lua5_1_4_Win64_bin\lua5.1.exe`. Then you add the path
`C:\lua5_1_4_Win64_bin\` to your enivironment variable "Path". Now navigate to
where you have meowth project and run `lua5.1.exe .\test_meowth.lua`.

## Linux (Ubuntu)

Install Lua 5.1 with `apt install lua5.1`. Navigate to where you have meowth
project and run `lua5.1 .\test_meowth.lua`.

# Notes

I followed the Lua style at https://github.com/Gethe/wow-ui-source/tree/live/AddOns.

Indent with tabs, you can use any size since tab size is based on viewer/editor


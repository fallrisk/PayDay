
Pay Day is an addon for WoW The Burning Crusade 2.4.3. It is based on the
description of [Cross Gambling](https://atamis.me/crossgambling/).

PayDay is maintained at https://github.com/fallrisk/PayDay.

The code for Pay Day is mostly just WoW addon related. For the Cross Gambling
implementation refer to the library Meowth located in the libs directory.

The icon comes from [Jedflah](https://www.deviantart.com/jedflah) at Deviant
Art. Here is a [direct
link](https://www.deviantart.com/jedflah/art/Minimalist-Meowth-Icon-Free-to-use-629282034)
to the image. Thank you JedFlah.

# Install

Go to the [releases](https://github.com/fallrisk/PayDay/releases) page and
choose the release you want (usually you want latest). Then under assets click
**"Source code (zip)"**. Extract the file to your AddOns directory. You have
to rename your directory to "PayDay" if it has a name like
"PayDay-2020.1-beta3".

# Usage

You can type `/pd` or `/payday` to show the PayDay frame, which looks like this:

You start a match with "Start Match". At that point people can join or leave the match.
Once everyone has joined you can start the roll with "Start Roll". Once everyone has
rolled the rolls are analyzed and ties are determined.

Between matches you can print the stats with "Print Stats". It prints the top 3 and
bottom 3 if you have more than 6 people, otherwise it will print all the gambler's.
If you want to display a gambler that isn't in the top 3 or bottom 3 you can right
click "Print Stats" and select a gambler's name.

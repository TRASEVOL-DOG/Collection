
This file expores the idea of letting others add their games to the project, as part of the chaining progression.

Potentially, after/at the gameover, the player could choose between 2 original-project games and 1/2 user-made games.

Issues to solve:

1. how to inforce users to actually use the framework?

2. how do we moderate user-made games? (avoiding both games that are too difficult/doesn't fit the project and games that have abusive content)

3. how do users add/submit games to the project?




Solutions:

#### Issue 1: inforce users to use the framework.

- Idea:
we could build a game maker Castle project, specifically for making games for our project. It could have tools to easily use the assets of the project and could provide a really nice experience to the user.
This would also let us put the user in a sandbox where they can't cheat out of the framework and break the chain or the project features in any way.
Potentially, projects could be submitted through this game maker, and it would be stored as code in the [Castle game storage](https://castle.games/documentation/storage-api-reference). Then to play the game, this game maker would be launched with a key to find the game back, compile its code (using the [load function](https://stackoverflow.com/questions/48629129/what-do-load-do-in-lua)) and play it.
One potential problem with this is that people are not able to upload the game to their profile, although, a simple solution to this would be to generate a lua file that simple launches the game maker with the right identifier key, and the user can use that file to create a project to showcase on their profile.



#### Issue 2: moderation

- Idea:
For user-made games, we could have a section in the Castle ui panel, dedicated to moderation, where players could report a game as impossible, offensive or otherwise abusive.
Possibly we could also include a little rating thing which could let us prioritize better games to get chosen as random games?
We would probably need to signal that report feature to make sure the player knows about it. Maybe put it on the top of the ui panel.
Games that are signaled by more than 3/5 users would stop being picked randomly and would have to be reviewed by a human being before going back into the project or deleted.
One potential problem with this is player abuse, reporting games that shouldn't be reported. Not much we can do about that besides reviewing reported games ourselves I think?


#### Issue 3: game submission

I can't see any way to manage this as of yet. The following ideas require new Castle features which don't seem totally unreasonable to ask for.

- Idea A:
With the game maker thing, we can store all the submitted (through the game maker itself) games in the Castle storage feature. We could ask Castle to let any project read (and only read) other project's storage. That way we could get games' info (name + preview) for choosing on a game's end screen.

- Idea B:
Using the Castle post feature: a game could be submitted as a post, with the game data attached, and then we would need for projects to be able to get posts and their data. (with some sort of post hashtags maybe?)
Note that, much like with issue #1, we should ensure that projects submitted actually use the framework, if they are to be added automatically to the project.



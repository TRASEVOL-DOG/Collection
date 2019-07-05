
Title:
- ???????
- "Box", "Toy", "Play", "Collection", "(Wario)Ware", "Loop"
- "Collection" = project codename


Flow:
(some ideas we haven't discussed in there - totally up to debate)
The player enters either through the 'hub', either through any one game that's part of the project.
A visible UI bar (top of the screen) shows the name of the current game, the author (?) and a battery icon.
The battery gets spent through the game (each games takes 10%?) but then good scores give you battery back. (up to 20%??)
Each game gives you a score out of 100, with a corresponding letter grade. (e.g. A+ for 96/100)
At the end of each game, you're shown your score and you get to choose between 2/3 (?) games to play next.
Each game is super simple and should only take 1-3 days to make.


Constraints:

- resolution: 256 x 192 ? (4/3)

- sprites:
  - bank of 16 x 16 glyph-style sprites
  - each sprite has two colors, a main one and another for anti-alias and details
  - + 8 x 8 equivalents (x)
  - to be made as needed
  - there will be a function to easily draw sprites with the 2 colors you choose
  
- palette:
  - Something like UFO50, with a big palette but each game only uses up to 8
  - 48 (?) colors for the palette
  - make our own
  
- font:
  - common for every game
  - maybe Hunger ([https://twitter.com/somepx/status/1136280740977676293]) (I have the pro version of that font, with the extended character set)
  
- audio:
  - bank of sfx
  - complementary music loops like in Luftrausers (?)
    - (you could choose a bass loop and a drum loop and play them together)
    
- themes for the games:
  - go wild!
  - the broader range the better.
  - e.g.: fishing, racing, world dominion, cell simulator, ...
  
- game necessities:
  - game always has an end
  - aim between 1 and 3 minutes of playtime
  - always give out a score ?/100, corresponding to a F-A (-/+) grade.
  - minimal gameplay, with minimal controls
  - there can be a lose condition but it's not necessary
  - there can be a win condition (and it's better) but it's not necessary
  - game takes in a difficulty setting (20-25 = peak difficulty)
  - make each game in 1 day whenever possible. Take only up to 3 days for any game.
  - every game should have a player sprite, to be used for transitions between games.


Pre-made stuff for the games:

- setup function:
  - init sugar + palette + sprites + font
  - pass the game's name, the chosen palette colors, the input list (?), a one-sentence description.

- control screen:
  - shows up before the game actually starts
  - stays there until player presses enter/start
  
- pause screen:
  - stops updating game + obscure the last frame
  - opens a settings panel as well
  
- end screen:
  - displays score
  - pass stats to display above score (?) e.g. : "small fish: +15", "big fish: +50", "boot: -20"
  + separate screen for selection of next game

- interface input system:
  - only allow arrows/wasd + 2 action keys + mouse position and state
  - automatic correspondance with game controllers
  - easier to show nicely on control screen
  
- glyph/sprite function:
  - glyph(n, x, y, width, height, angle, color_a, color_b)
  - width and height are for stretching
  - outlined_glyph(n, x, y, width, height, angle, color_a, color_b, outline_color)
  
- UI bar:
  - top of screen
  - shows game's name
  - shows game's creator (?)
  - shows total score so far (?)
  - shows battery

- chain end screen:
  - submit score button -> goes to 'hub' game which has the leaderboard
  - remember all scores (each time: new score entry)
  - choose name for each score entry (defaults to Castle username) -> 5 characters on wheels (remembers last entry name)
  - new game button


game registry file:
```lua
{
  {
    "fishing game",
    "urlOfTheGame",
    "urlOfThePreview",
    playerSprite
  },
  {
    "lumberjack game",
    "urlOfTheGame",
    "urlOfThePreview",
    playerSprite
  },
}
```

Pixel-art references:

[https://ilkke.itch.io/]
Ilkke is like a pixel-art god. He works a lot with retro limitations. The way he does his lighting is extremely good. He's particularly good at giving the impression of volume which is what we should focus on in this reference.

He worked on this game which came out very recently, it uses just four colors and looks oh so good:
[https://twitter.com/Nitrome/status/1139173726841397248]
[https://apps.apple.com/app/id1277023608]


[https://medium.com/pixel-grimoire/how-to-start-making-pixel-art-2d1e31a5ceab]
[https://medium.com/pixel-grimoire/how-to-start-making-pixel-art-4-ff4bfcd2d085]
Saint11 is the main pixel artist behind Celeste! He's been making some very good tutorials full of good advice! There are 8 of them currently but these above are the two that I want you to check out. The first is a really good intro and in particular talks about lines, which is super important at very low resolutions. The other one is about anti-alias and we want that in our sprites, as it will make then a lot smoother, so it's super important too!


[https://twitter.com/crrackerjack/media] (do some scrolling to get to the pixel-art stuff)
This is going to be my favorite reference for this project. I absolutely love this artist's style. Try to look for the line/color-separation patterns and pay attention to the anti-alias. Her style gives really full shapes with super smooth lines and yet very few colors. And looks at the shapes! They're so clean and good!
It's so goooood! (I'm a fanboy)


I think we should go for very full shapes, and put emphasis on clean smooth lines, using a ton of anti-alias and make clean lines inside the shapes for details.
Do the shapes with color A and then the anti-alias and detail lines with color B.
Use as much space as you can in these 16x16 boxes!


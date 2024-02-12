<img src="https://github.com/git-learning-game/oh-my-git/blob/main/images/oh-my-git.png" width="400">

**Oh My Git!** is an open-source game about learning Git!

## Play the game!

You can download binaries for Linux, macOS, and Windows [from itch.io](https://blinry.itch.io/oh-my-git)!

## Report bugs!

If something doesn't work or looks broken, please let us know! You can describe the issue you're having [in our issue tracker](https://github.com/git-learning-game/oh-my-git/issues).

If you have ideas for new features, we'd be excited to hear them! Also in that case, we invite you to [open an issue](https://github.com/git-learning-game/oh-my-git/issues)!

## Build your own level!

Wanna build your own level? Great! Here's how to do it:

1. Download the latest version of the [Godot **3** game engine](https://godotengine.org/download/3.x). Godot 4 is not supported yet.
1. Clone this repository.
1. Run the game – the easiest way to do so is to run `godot scenes/main.tscn` from the project directory.
1. Get a bit familiar with the levels which are currently there.
1. Take a look into the `levels` directory. It's split into chapters, and each level is a file.
1. Make a copy of an existing level or start writing your own. See the documentation of the format below.
1. Write and test your level. If you're happy with it, feel free to send it to us in a pull request! <3

### Level format

```
title = This is the level's title

[description]

This text will be shown when the level starts.

It describes the task or puzzle the player can solve.

[cli]

(optional) This text will be shown below the level description in a darker color.

It should give hints to the player about command line usage and also maybe some neat tricks.

[congrats]

This text will be shown after the player has solved the level.

Can contain additional information, or bonus exercises.

[setup]

# Bash commands that set up the initial state of the level. An initial
# `git init` is always done automatically. The default branch is called `main`.

echo You > people_who_are_awesome
git add .
git commit -m "Initial commit"

[win]

# Bash commands that check whether the level is solved. Write these as if you're
# writing the body of a Bash function. Make the function return 0 if it's
# solved, and a non-zero value otherwise. You can use `return`, and also, Bash
# functions return the exit code of the last statement, which sometimes allows
# very succinct checks. The comment above the win check will be shown in the game
# as win condition text.

# Check whether the file has at least two lines in the latest commit:
test "$(git show HEAD:people_who_are_awesome | wc -l)" -ge 2
```

A level can consist of multiple repositories. To have more than one, you can use sections like `[setup <name>]` and `[win <name>]`, where `<name>` is the name of the remote. The default name is "yours". All repositories will add each other as remotes. Refer to the [remote](levels/remotes) levels examples.

### Level guidelines

At this stage, we're still exploring ourselves which kind of levels would be fun! So feel free to try new things: basic introductions with a little story? Really hard puzzles? Levels where you have to find information? Levels where you need to fix a problem? Levels with three remotes?

## Contribute code!

To open the game in the [Godot editor](https://godotengine.org), run `godot project.godot`. You can then run the game using *F5*.

Feel free to make improvements to the code and send pull requests! There is one exception: because merge conflicts in Godot's scene files tends to be hard to resolve, before working on an existing *\*.tscn* file, please get in touch with us.

To build your own binaries, you'll need Godot's [export templates](https://docs.godotengine.org/en/stable/getting_started/workflow/export/exporting_projects.html), and `zip`, `wget`, and `7z`. Then, run `make`. On Debian/Ubuntu, the Godot binary is called `godot3`, you might need to adjust the paths in the Makefile.

## Code of Conduct

We have a [Code of Conduct](CODE_OF_CONDUCT.md) in place that applies to all project contributions, including issues and pull requests.

## Funded by

<a href="https://www.bmbf.de/en/"><img src="https://www.dipf.de/en/images/BMBF_4C_M_e.jpg/@@download/image/BMBF_4C_M_e.jpg" alt="Logo of the German Ministry for Education and Research" height="100px"></a>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <a href="https://prototypefund.de/en/"><img src="https://raw.githubusercontent.com/prototypefund/ptf-ci/main/logos/PrototypeFund-Icon.svg" alt="Logo of the Prototype Fund" height="100px"></a>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <a href="https://okfn.de/en/"><img src="https://upload.wikimedia.org/wikipedia/commons/4/4d/Open_Knowledge_Foundation_Deutschland_Logo.svg" alt="Logo of the Open Knowledge Foundation Germany" height="100px"></a>

## Thanks

- "success" sound by [Leszek_Szarzy, CC0](https://freesound.org/people/Leszek_Szary/sounds/171670/)
- "swish" sound by [jawbutch, CC0](https://freesound.org/people/jawbutch/sounds/344408/)
- "swoosh" sound by [WizardOZ, CC0](https://freesound.org/people/WizardOZ/sounds/419341/)
- "poof" sound by [Saviraz, CC0](https://freesound.org/people/Saviraz/sounds/512217/)
- "buzzer" sound by [Loyalty_Freak_Music, CC0](https://freesound.org/people/Loyalty_Freak_Music/sounds/407466/)
- "typewriter_ding" sound by [_stubb, CC0](https://freesound.org/people/_stubb/sounds/406243/)

## License

[Blue Oak Model License 1.0.0](LICENSE.md) – a [modern alternative](https://writing.kemitchell.com/2019/03/09/Deprecation-Notice.html) to the MIT license. It's a a pleasant read! :)

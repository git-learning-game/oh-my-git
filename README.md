# git-hydra

**git-hydra** (working title) is an open-source game about learning Git!

The current form is an early prototype, and will change significantly until the end of February 2021.

## Play the game!

You can download binaries of the game here:

- [Linux](https://git-learning-game.github.io/git-hydra/linux/git-hydra.zip)
- [macOS](https://git-learning-game.github.io/git-hydra/mac/git-hydra.zip)

We'll also have a Windows version soon – stay tuned! :)

## Report bugs!

If something doesn't work or looks broken, please let us know! You can describe the issue you're having [in our issue tracker](https://github.com/git-learning-game/git-hydra/issues).

If you have ideas for new features, we'd be excited to hear them! Also in that case, we invite you to [open an issue](https://github.com/git-learning-game/git-hydra/issues)!

## Build your own level!

Wanna build your own level? Great! Here's how to do it:

1. Download the latest version of the [Godot game engine](https://godotengine.org).
1. Clone this repository.
1. Run the game – the easiest way to do so is to run `godot main.tscn` from the project directory.
1. Get a bit familiar with the levels which are currently there.
1. Take a look into the `levels` directory. It's split into chapters, and each level is a file.
1. Make a copy of an existing level or start writing your own. See the documention of the format below. Put your level in the `contrib` chapter.
1. The dropdowns in the game will automatically refresh to contain your level, you don't need to restart the game.
1. Write and test your level. If you're happy with it, feel free to send it to us in a pull request! <3

### Level format

```
title = This is the level's title

[description]

This text will be shown when the level starts.

It describes the task or puzzle the player can solve.

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
# very succinct checks.

# Check whether the file has at least two lines in the latest commit:
test "$(git show HEAD:people_who_are_awesome | wc -l)" -ge 2
```

A level can consist of multiple repositories. To have more than one, you can use sections like `[setup <name>]` and `[win <name>]`, where `<name>` is the name of the remote. The default name is "yours". All repositories will add each other as remotes. Refer to the [experiments/pull-merge-push](levels/experiments/pull-merge-push) level for an example.

### Level guidelines

At this stage, we're still exploring ourselves which kind of levels would be fun! So feel free to try new things: basic introductions with a little story? Really hard puzzles? Levels where you have to find information? Levels where you need to fix a problem? Levels with three remotes?

## Contributing code

Feel free to make improvements to the code and send pull requests! There is one exception: because merge conflicts in Godot's scene files tends to be hard to resolve, before working on an existing *\*.tscn* file, please get in touch with us.

## Code of Conduct

We have a [Code of Conduct](CODE_OF_CONDUCT.md) in place that applies to all project contributions, including issues and pull requests.

## Funded by

<a href="https://www.bmbf.de/en/"><img src="https://timelens.io/assets/images/bmbf.svg" alt="Logo of the German Ministry for Education and Research" height="100px"></a>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <a href="https://prototypefund.de/en/"><img src="https://timelens.io/assets/images/prototypefund.svg" alt="Logo of the Prototype Fund" height="100px"></a>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <a href="https://okfn.de/en/"><img src="https://timelens.io/assets/images/okfde.svg" alt="Logo of the Open Knowledge Foundation Germany" height="100px"></a>

## License

[Blue Oak Model License 1.0.0](LICENSE.md) – a [modern alternative](https://writing.kemitchell.com/2019/03/09/Deprecation-Notice.html) to the MIT license. It's a a pleasant read! :)

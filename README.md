# Math Quiz

Math Quiz is a small Mac app for a child of about 9 (roughly 3rd and 4th grade). A round is 10 questions. The big button has no timer. Lightning round is optional: 20 seconds for each question.

Topics are addition and subtraction (including carrying and borrowing), multiplication and division facts through 12, simple fractions, place value, and short word problems. Three correct answers in a row make that topic one step harder. Two misses in a row ease it back. One miss does not.

A miss shows the right answer and a short hint. Stars, streaks, and badges are on the progress screen. There is no account, no network, and no ads. The app does not pick a name. **Your name** can be left blank.

## Download and install

The built app is on the releases page:

https://github.com/matjns/kids-math-quiz/releases

Download `MathQuiz-mac-universal.zip`. It runs on Apple silicon and on Intel, and it needs macOS 14 or later. It is not signed with an Apple Developer ID, so macOS warns the first time you open it. The steps (Control-click, Open, and `xattr -cr` if macOS says the app is damaged) are in `README-mac.txt` inside the release.

Put `Math Quiz.app` in `/Applications`.

## Kids Computer

Kids Computer is the launcher (https://github.com/matjns/kids-computer). Its Math Quiz tile asks macOS to open the app whose bundle id is `com.kidscomputer.mathquiz`. That only works after Math Quiz is in `/Applications` (or has been opened once, so macOS knows the id).

Math Quiz does not hide the Dock, take over the menu bar, or quit other apps. Command-Q quits. Closing the window quits too. The launcher is still running and comes back.

## Where progress is saved

Progress is a file on this Mac: `progress.json`, in an Application Support folder named `MathQuiz`. Nothing is uploaded.

The downloadable app is sandboxed, so macOS keeps that folder inside the app's private container:

`~/Library/Containers/com.kidscomputer.mathquiz/Data/Library/Application Support/MathQuiz/progress.json`

## Build it yourself

You need a Mac with macOS 14 or later, and Xcode 15 or later. Open Xcode once after installing it.

```bash
./build.sh test
./build.sh
```

`./build.sh test` checks the question logic. It also runs on Linux, anywhere Swift is installed. `./build.sh` writes `build/Math Quiz.app` and `dist/MathQuiz-mac-universal.zip`.

The questions, scoring, and difficulty live in `MathQuizCore`. The window is the `MathQuiz` target.

What is left before an App Store submission is written out in `docs/APP_STORE.md`.

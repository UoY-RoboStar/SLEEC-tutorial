# SLEEC-tutorial

This repository contains a Dockerfile that incorporates [LEGOS-SLEEC](https://github.com/Kevin-Kolyakov/sleec-intellij-plugin) and [SLEEC-TK](https://github.com/UoY-RoboStar/SLEEC-TK/) in a single environment that can be used from a web browser. The image targets the Intel/AMD64 architecture but can be executed on macOS under Rosetta emulation, which should be enabled by default for [Docker](https://docs.docker.com/desktop/setup/install/mac-install/).

## Pre-requisites

* Docker (Intel/AMD64 or Apple Silicon under emulation)

## Usage
To execute the prebuilt docker image, open a terminal and use the command:
```
docker run --platform linux/amd64 -it --name sleec-tutorial -p 8080:8080 ghcr.io/uoy-robostar/sleec-tutorial:main
```
After a short while, you should then be able to open a web browser at [http://localhost:8080](http://localhost:8080) to interact with the Linux-based XFCE4 desktop environment as reproduced in the screenshot below. The window can be resized as needed.

![SLEEC environment](/img/sleec-environment.png)

### Building the Docker image (optional)
To build the Docker image in this repository from scratch use the command:
```
docker build --platform linux/amd64 -t sleec-tutorial .
```

### SLEEC-TK
To use SLEEC-TK for analysis, you should, first of all, setup the CSP model-checker [FDR4](https://cocotec.io/fdr/) following the instructions below.

#### Install and activate FDR4
To setup FDR4, click on the shortcut in the desktop named `FDR4 (Launch or Install)`. A terminal will open, and if FDR is not yet installed it will be automatically installed. At the end, press Enter to launch FDR and proceed to obtain a license following the instructions on the screen. You can then close the FDR window that appears afterwards.

#### Running SLEEC-TK
To run SLEEC-TK, double-click on the `SLEEC-TK` shortcut on the desktop. The Eclipse launcher will appear, followed by a dialog asking for selecting a workspace path. If asked, you can accept the default `/home/sleec/eclipse-workspace` by clicking on `Launch`.

#### Reproducing results of pair-wise consistency validation
In SLEEC-TK, a file with extension `file.sleec` leads to the automatic generation of four files under the folder `src-gen` that are used as part of model-checking with FDR4:

* `instantiations.csp` : In this file, the user can override the domain for the type of numeric types used in the SLEEC rules.
* `tick-tock.csp` : This is a mechanisation for FDR of the `tock-CSP` semantics and related operators.
* `file.csp` : This file contains the `tock-CSP` semantics of SLEEC rules defined in `file.sleec`.
* `file-assertions.csp` : This file contains assertions for verification with FDR of conflicts and redundancies, as explained next.

**Note 1**: The above files can be re-generated anew by triggering a clean of the Eclipse project, namely, by selecintg `Project` from the menu bar, followed by `Clean...`.

**Note 2**: In the case of the `tutorial.sleec` file provided in the sample project, the generated files are named `tutorial.csp` and `tutorial-assertions.csp`.

The file `file-assertions.csp` will contain assertions for identifying conflicts and redundancies for SLEEC rules as described in Section 3.1 of the tutorial paper. For example, the file `tutorial-assertions.csp` can be loaded `tutorial-assertions.csp` using the FDR graphical interface by right-clicking on `tutorial-assertions.csp` under the Model Explorer view, and selecting `Open With` > `Other`, then selecting the External program `FDR`, as reproduced below.

![Opening .csp file from SLEEC-TK](/img/OpenCSPFile.png)

If successful, this will show a window similar to that reproduced below.

![Screenshot of FDR graphical interface](/img/FDRWindow.png)

Here, the pane on the right lists assertions related to the SLEEC Rules. We explain below, how to use the graphical interface of FDR to reproduce the traces of Section 3.1.

##### Traces

To reproduce `Trace 1 for Rule1` load `tutorial-assertions.csp` into FDR. Then, first type `external chase` in FDR's interactive prompt to the left followed by the Enter key. Then, type `:probe chase(SLEECRule1)` to bring up FDR's probing interface of the `tock-CSP` semantics for Rule1. This is shown as a tree, which can be used to follow a sequence of interactions, as reproduced below.

![Trace1 for Rule1 using :probe chas(SLEECRule1)](/img/SLEECRule1.png)

In this case, the trace to be reproduced is `CurtainOpenRqt, userUnderDressed.false, userDistressed.medium, tock, CurtainsOpened`, as shown at the bottom of the screenshot. Arrow keys or the mouse cursor can be used to step through the possible interactions.

The same procedure can be used to explore `Trace 3 for RuleB` and `Trace4 for RuleA`, that is, `:probe chase(SLEECRuleB)` and `:probe chase(SLEECRuleA)`, reproduced below.

![Trace3 for RuleA](/img/SleecRuleB.png)
![Trace4 for RuleA](/img/SleecRuleA.png)

##### Conflicts

Conflict checking of a pair of rules, for example, Rule1 and Rule2, is encoded as two assertions `SLEECRule1Rule2 :[deadlock free]` and `SLEECRule1Rule2CF :[divergence free]`, as seen in the screenshot below as `tutorial-assertions.csp` is loaded into FDR:

Clicking on `Check` for both reveals that they both `Passed`, indicating the the rules are not conflicting as expected.

For analysis of conflicts discussed in Section 3.1 of the paper, we consider the set of SLEEC rules (RuleA, RuleB, and RuleC), defined in Listing 1.2, and specified at the end of the file `tutorial.sleec`. By scrolloing the `Assertions` list in FDR, it is possible to find the pair of assertions
`SLEECRuleARuleB :[deadlock free]` and `SLEECRuleARuleBCF :[divergence free]`. Clicking on `Check`
reveals that the first assertion does not pass, indicating that there is a conflict. The counter-example is produced by clicking on `Debug`:

![Trace 2 showing conflict between RuleA and RuleB](/img/SLEECRuleARuleB.png)

This should reveal the counter-example as reproduced above `CurtainOpenRqt, userUnderDressed.true, userUnderDressed.true,userDistressed.high, tock, tock, tock, tock, tock, tock`.

##### Redundancies

Redundancies, as discussed in Section 3.1 of the paper, are encoded via two refinement assertions, for rules whose alphabet has some event in common. 

With `tutorial-assertions.csp` open in FDR, the checking of redundancy between rules RuleC and RuleB is encoded by assertions `not RuleB_wrt_RuleC [T= RuleC_wrt_RuleB` (is Rule C redundant wrt. Rule B?) and `not RuleC_wrt_RuleB [T= RuleB_wrt_RuleC` (is RuleB redundant wrt. Rule C?).

Checking `not RuleC_wrt_RuleB [T= RuleB_wrt_RuleC` produces a counter-example similar to that reported in the paper as `Trace 5`, a scenario indicating that `RuleB` is not redundant with respect to `RuleC`. The counter-examples obtainable from FDR contain several permutations across the 60 occurrences of the subsequence `(userUnderDressed.X, tock)` mentioned in the paper, corresponding to all possible reading of value `true` or `false` for `userUnderDressed`. 

Proof that `Trace 5` is indeed a genuine counter-example of the negated version of the assertion, i.e. `RuleC_wrt_RuleB [T= RuleB_wrt_RuleC` can be obtained using the file `tutorial-assertion-trace5.csp`, included for completeness, that contains two assertions:

* `assert not RuleC_wrt_RuleB :[has trace [T]]: <trace ...>` : where `trace` is `Trace 5` reproduced in the paper, this assertion checks that `trace` is not a valid trace of `RuleC_wrt_RuleB`.
* `assert RuleB_wrt_RuleC :[has trace [T]]: <trace ...>` : similarly `trace` is `Trace 5`, and this assertion checks that `trace` is a valid trace of `RuleB_wrt_RuleC`, that is, it is possible.

Checking that both assertions pass indicates that `trace` is a valid counter-example, that is, the refinement `RuleC_wrt_RuleB [T= RuleB_wrt_RuleC` does not hold, as `trace` is a valid observation of `RuleB_wrt_RuleC` but not `RuleC_wrt_RuleB` as expected.

#### Reproducing results of conformance verification of design models
The design models reproduced in Section 4 of the paper can be opened from the provided `RAD0` Eclipse project. We observe that, upon loading the project, you will be asked whether to open these diagrams. To manually open `MonitoringService` (Figure 4 in the paper), one of the included RoboChart diagrams, select the file `system.rct` under the `Model Explorer` view, and expand the tree structure: `RC Package RAD`, followed by double clicking on `MonitoringService`. The diagram will then appear to the right as reproduced below.

![Screenshot of MonitoringService open](img/MonitoringService.png)

The RoboChart models of Figures 5 and 6 in the paper are similarly available under `RC Package RAD`. 

##### Verification
Similarly to the pair-wise validation of SLEEC rules, conformance verification also requires that FDR4 has been installed and activated. The assertions are included in the file `rad.assertions` that can be edited by double-clicking, as reproduced below.

![Screenshot of rad.assertions open in SLEEC-TK](img/RADAssertions.png)

###### Checking using SLEEC-TK's integration with FDR

Before verifying the assertions, configure FDR4 for use with SLEEC-TK by selecting `Window` from the menu bar, and then choosing `Preferences`. In the dialog that appears, using the tree show on the left select `RoboChart` > `Analysis`, then type the path `/opt/fdr`. Eclipse may ask you for `Preference Synchronization`, choose `No - Preferences will be saved locally.`, followed by `Ok` twice.

With the file `rad.assertions` open in SLEEC-TK, locate the red icons next to the label `CSP` below the Eclipse menu bar. Click on the second icon to the right of the label `CSP` in red:

![Running assertions check](img/CSPLabel.png)

If successful, you should see a status bar at the bottom of SLEEC-TK:

![Running assertions check with FDR in the background](img/FDR-progress.png)

At this point, FDR is running in the background to check that assertions `A1` to `A4`, specified in the file `rad.assertions` are satisfied. **This process may take a significant amount of time to complete.** At the end, an HTML is produced.

###### Checking using FDR directly
To check conformance assertions directly with FDR, instead, select the file under the folder `csp-gen/rad_assertions.csp` and load it into FDR. Assertions `A1` to `A2` are listed in order and can be checked from within FDR. `A1` and `A2` should pass while `A3` fails. `Trace 6`, in particular, can be obtained by examining the last assertion with `csp-gen/rad_assertions.csp` loaded into FDR.

# README

This repository is used to build a panel of arbitrage-implied riskless rates. This panel is used in [Segmented Arbitrage](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3960980) by Siriwardane, Sunderam, and Wallen (2023). Please cite the paper if you would like to use the data:
```
@article{SSW2023,
author = {Siriwardane, Emil N. and Sunderam, Adi and Wallen, Jonathan},
journal = {SSRN},
title = {The Rise of Alternatives},
year = {2023}
}
```

As described in more detail below, the repository relies heavily on data from Bloomberg. Because Bloomberg occasionally updates and modifies its historical data, the output of the repository is also subject to change, though we expect any such changes to be minor. 

The main analysis in our original paper uses data after 2010. However, the repo will populate arbitrage spreads and implied riskless rates prior to 2010 when the underlying data is available from Bloomberg. We therefore recommend that users carefully study the data prior to 2010 before using it for any subsequent analyses.

The ultimate output of the repo can be found in ``aggregation/output``. There, we produce several files that contain implied riskless rates and arbitrage spreads, all reshaped in various ways (e.g., wide, panel, or averaged to the strategy level). 

## Requirements
All requirements must be installed and set up for command line usage. For further detail, see the [Command Line Usage](#command-line-usage) section below.

We manage Python installations using conda or miniconda. 
To build the repository as-is, the following applications are additionally required:

* [git-lfs](https://git-lfs.github.com/)
* [Stata](https://www.stata.com/install-guide/)

These software are used by the scripts contained in the repository. By default, the [Setup](#setup) and [Build](build) instructions below will assume their usage.

In addition, to access all of the input data for building arbitrage spreads, users must have the appropriate Bloomberg access and the Bloomberg Excel Plug-in installed.

## Setup 

1. Enable program calls from the command line (e.g., Stata). See the [RA manual](https://github.com/gentzkow/template/wiki/Command-Line-Usage) used by [gslab-econ](https://github.com/gslab-econ) for more detailed instructions on how to do so. 

2. Clone the repository locally. From the command line, this would be done via:
    ```
    git clone https://github.com/esiriwardane/arbitrage-spreads.git
    ```

3. Create a `config_user.yaml` file in the root directory by copying the template found in the `setup` subdirectory using the following command run from the root directory:
    ```
    cp setup/config_user_template.yaml config_user.yaml
    ```
    
4. Populate all of the Excel Bloomberg templates in ``root/raw/bloomberg_templates`` and copy them to ``root/raw/``

5. If you already have conda setup on your local machine, make sure you run `conda update conda`, or else you will have errors creating the conda environment. If you do not have conda setup, the following steps will install a lightweight version of conda that will not interfere with your current python installations.
Install miniconda and jdk to be used to manage the R/Python virtual environment, if you have not already done this. You can install these programs from their websites [here for miniconda](https://docs.conda.io/en/latest/miniconda.html) and [here for jdk](https://www.oracle.com/java/technologies/javase-downloads.html). If you use homebrew (which can be download [here](https://brew.sh/)) these two programs can be downloaded as follows:
   ```
   brew install --cask miniconda
   brew install --cask oracle-jdk
   ```
   Once you have done this you need to initialize conda by running the following lines and restarting your terminal:
   ```
   conda config --set auto_activate_base false
   conda init $(echo $0 | cut -d'-' -f 2)
   ```
   
   On Windows, instead run:
   ```
   conda config --set auto_activate_base false
   conda init cmd.exe
   ```

6. Create a local conda environment to use with the project with the command:
   ```
   conda env create -f setup/conda_env.yaml
   ```
   To run Python commands thereafter, you must first activate the conda environment using `conda activate arbitrage-spreads`.

7. Fetch `gslab_make` submodule files. We use a [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to track our `gslab_make` dependency in the `lib/gslab_make` folder. To add the submodule, run the following bash command from the `root` directory.
   ```
   rm -rf lib/gslab_make/
   git submodule add https://github.com/gslab-econ/gslab_make.git lib/gslab_make
   git submodule init
   git submodule update
   ``` 
   Once these commands have run to completion, the `lib/gslab_make` folder should be populated with `gslab_make` files.
   

8. Change to the `root/setup` subdirectory, then run the following bash command in a terminal:
   ```
   python check_setup.py
   ```
   
   A common reason this test fails is that users have not activated their conda environment (see [Usage](#usage) section)

9. Install Stata dependencies. To do so, change to `root/setup` and run:

    ```
    stata-mp download_stata_ado.do
    ````   
    On Windows, you will need to change the command `stata-mp` to the appropriate command line call on your machine.

   
## Usage

### Always Activate Conda Environment

Once you have succesfully completed the [Setup](#setup) section above, each time that you run the analysis make sure the virtual environment associated with this project is activated, using the command below (replacing with the name of this project).
```
   conda activate arbitrage-spreads
``` 


If you wish to return to your base installation of python and R you can easily deactivate this virtual environment using the command below:
```
   conda deactivate
``` 

### Build
_Build the Entire Panel of Arbitrage Spreads from Scratch:_
1. Follow the *Setup* instructions above.

2. Activate the Conda environment you created for the projecct 

3. From the root of repository, run the following bash command:
   ```
   python run_all.py
   ```

The repo has a modular structure, which means each module (e.g., ```root/cip``` or ```root/equity-sf```) can be built from scratch. This is useful because it allows users to develop code without needed to re-run potentially length data cleaning steps each time. 

### Command Line Usage

For specific instructions on how to set up command line usage for an application, the [RA manual](https://github.com/gentzkow/template/wiki/Command-Line-Usage) used by [gslab-econ](https://github.com/gslab-econ) is a good reference.

By default, the repository assumes the following executable names for the following applications:

```
python      : python
git-lfs     : git-lfs
stata       : stata-mp (will need to be updated if using a version of Stata that is not Stata-MP)
matlab      : matlab
```

Default executable names can be updated in `config_user.yaml`. For further detail, see the [User Configuration](#user-configuration) section below.

## User Configuration
`config_user.yaml` contains settings and metadata such as local paths that are specific to an individual user and thus should not be committed to Git. Required applications may be set up for command line usage on your computer with a different executable name from the default. If so, specify the correct executable name in `config_user.yaml`. This configuration step is explained further in the [RA manual](https://github.com/gentzkow/template/wiki/Repository-Structure#Configuration-Files) used by [gslab-econ](https://github.com/gslab-econ)

## Windows Differences
The instructions above are for Linux and Mac users. However, with just a handful of small tweaks, this repo can also work on Windows. 

For example, for the set up unix commands such as rm -rf are rmdir /s in windows

If you are using Windows, you may need to run certain bash commands in administrator mode due to permission errors. To do so, open your terminal by right clicking and selecting `Run as administrator`. To set administrator mode on permanently, refer to the [RA manual](https://github.com/gentzkow/template/wiki/Repository-Usage#Administrator-Mode) used by [gslab-econ](https://github.com/gslab-econ).

If your username has spaces in it (e.g. your file system looks like ``C:\Users\First Last\``), there may be [issues](https://stackoverflow.com/questions/42152589/anaconda-failed-to-create-process) calling Anaconda from the command line. A simple solution is to clone the repository in a directory whose path does not contain spaces (e.g., ``C:\Github\template``).

The executable names specified in `config_user.yaml` are also likely to differ on your computer if you are using Windows. Executable names for Windows will typically look like the following:

```
python      : python
git-lfs     : git-lfs
stata       : StataMP-64 (will need to be updated if using a different version of Stata that is not Stata-MP or 64-bit)
matlab      : matlab
```

To download additional `ado` files on Windows, you will likely have to adjust this bash command:
```
stata_executable -e download_stata_ado.do
```

`stata_executable` refers to the name of your Stata executable. For example, if your Stata executable was located in `C:\Program Files\Stata15\StataSE-64.exe`, you would want to use the following bash command:

```
StataMP-64 -e download_stata_ado.do
```

## License
MIT License

Copyright (c) 2021 Emil Siriwardane, Adi Sunderam, and Jonathan Wallen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

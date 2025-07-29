![https://static.psyc.dev/assets/github/saol-optim.svg](https://static.psyc.dev/assets/github/saol-optim.png)  
Saol. Copyright &copy; 2025, Michael Pascale. All rights reserved.

A virtual environment in which to study spatial nagivation, attention, orientation, and learning. From an Irish Gaelic word for _life_, including the encompassing conditional aspects of the world (environmental context). Implemented in C# for the Unity Engine.

Build Requirements:
- [Unity](https://unity.com/releases/editor/archive) 6 LTS (6000.0.40f1, Unity Technologies)
  Mono Runtime with [.NET Standard 2.1](https://learn.microsoft.com/en-us/dotnet/standard/net-standard?tabs=net-standard-2-1).
- [Parquet.NET](https://github.com/aloneguid/parquet-dotnet) (5.1.1, Ivan Gavryliuk)
  Used for efficient storage of behavioral data ([docs](https://aloneguid.github.io/parquet-dotnet/serialisation.html)).
- [ImageSharp](https://github.com/SixLabors/ImageSharp) (2.1.10, SixLabors)
  Used for processing of image stimuli ([docs](https://docs-v2.sixlabors.com/articles/imagesharp/index.html)).

The C# dependencies can be installed with [NuGet for Unity](https://github.com/GlitchEnzo/NuGetForUnity) (Patrick McCarthy).

At time of writing, development was conduted under [Fedora 41 Workstation](https://fedoraproject.org/workstation/download) (Linux 6.13.7-200.fc41.x86_64) with the [.NET 9.0.103 SDK](https://learn.microsoft.com/en-us/dotnet/core/install/linux-fedora?tabs=dotnet9).

<p align="center">
  <img src="https://github.com/user-attachments/assets/61e7f493-efcc-4834-8f56-e33718ec8ca9" alt="Procedurally generated hex grid world." width="800"/>
  <br>
  <em>A virtual open field, composed of procedurally generated hexagonal tiles in an arbitrary arrangement.</em>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/f438210f-a90a-49e1-a286-6b3c8815456a" alt="Another procedurally generated enclosed space." width="800"/>
  <br>
  <em>An enclosed space, generated from hexagonal tiles. Arbitrary stimuli appear on the walls, emulating an art gallery.</em>
</p>

## Stimuli

The image set _Snodgrass and Vanderwart 'Like' Objects_ (SVLO) is courtesy of Michael J. Tarr, Carnegie Mellon University and is used here as licensed under <a href="https://creativecommons.org/licenses/by-nc-sa/3.0/">CC BY-NC-SA 3.0</a> <img src="https://mirrors.creativecommons.org/presskit/icons/cc.svg" width=15><img src="https://mirrors.creativecommons.org/presskit/icons/by.svg" width=15><img src="https://mirrors.creativecommons.org/presskit/icons/nc.svg" width=15><img src="https://mirrors.creativecommons.org/presskit/icons/sa.svg" width=15>, retrieved from the [Tarr Lab website](https://sites.google.com/andrew.cmu.edu/tarrlab/stimuli).

These stimuli were originally publised in:  
Rossion, B., & Pourtois, G. (2004). Revisiting Snodgrass and Vanderwart's object set: The role of surface detail in basic-level object recognition. _Perception_, 33, 217-236.

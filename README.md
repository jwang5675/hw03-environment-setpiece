# CIS 566 Homework 3: Environment Setpiece
Jason Wang (jasonwa)

Warning, scene is really slow. Reducing resolution to the size of shadertoy and using Firefox will make the experience much better.

Scene Motivation:

![](images/motivation.jpg)

Demo: https://jwang5675.github.io/hw03-environment-setpiece/

Sources:
  - The math for SDFs/Normals/Etc. info was adopted from class slides or from http://www.iquilezles.org/

## Features Implemented
Here is a high-level overview of implemented features

	- Animation of the the sky box to simulate night and day, animation of water normals to create illusion of moving water waves, animation of boat to sway from side to side over time
	- Noise to create flattened 3d FBM wood texture on boat, fbm to offset normals to simulate water waves, fbm to create skybox colors, cloud fog, and star position
	- Sphere UV mapping far clip camera points to generate the skybox color for the scene
	- Use of sin and cos toolbox functions to have smooth animation and color smoothing with mix throughout the scenes skybox colors and shadows
	- Environment lighting using 2 ambient lights (one above the boat to have light at night time and one behind the sails to cause ripples with subsurface scattering), and 2 rotating lights representing the sun and the moon light for soft shadows on the boat/water and colored subsurface scatting on the boat sale during sunset and moonset.
	- SDF-based soft shadows as penumbra shadows using the light direction from the sun and moon

	- Ray-based specular reflection on the water using fbm displaced normals
   	- Rim lighting/Subsurface scattering on the boat sails
    - Small amount of distance fog added to the end of the water horizon to make the horizon darker in color compared to the foreground of the water.



## Implementation Details

There are 3 main aspects of the scene. I will discuss them in detail below.

Skybox:

Water:

Sailboat:

# SceneKit-Outline-Example
Outline shaders in SceneKit

![Output Sample](/images/ExampleCorrectOutput.png)

This repo shows an example of using SceneKit Technique passes and metal shaders to render a constant width solid outline around scenekit nodes in screen space.

The technique creates a mask by offsetting the vertices of the mesh by the normals in clip space. This will not work for meshes with sharp corners as seen
in the cube node. 

![Output Sample](/images/ExampleBadOutput.png)

The example project is setup for MacOS. Maybe I will add an iOS example project later. It should run on iOS with little or no changes.
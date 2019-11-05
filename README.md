# Spectral Coarsening
This is the MATLAB implementation of "Cubic Stylization" [Liu & Jacobson 2019]. The only dependency is the gptoolbox ```https://github.com/alecjacobson/gptoolbox```. After cloning it, cubic stylization only requires adding the path to gptoolbox by running the following commands in MATLAB
```
gp_subdirs = split(genpath('/path/to/gptoolbox/'),':');
addpath(strjoin(gp_subdirs(~contains(gp_subdirs,'.git')),':'));
savepath
```
![Result](./result.png |  width=100)

### bibtex
```
@article{Liu:CubicStyle:2019,
  title = {Cubic Stylization},
  author = {Hsueh-Ti Derek Liu and Alec Jacobson},
  year = {2019},
  journal = {ACM Transactions on Graphics}, 
}
```

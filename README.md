# Open-jLUISMR
Pure Julia based GUI for Modia built using Gtk

## Packages needed:
Modia, PyPlot, Gtk, Gtk.ShortNames
1) In Julia type: ]
2) Then type: add Modia, PyPlot, Gtk, Gtk.ShortNames, DelimitedFiles, ModiaResult
3) Download the files and extract the zip. Copy the folder named "Open_jLUISMR" to your working directory
4) To find the working directory in Julia, type: pwd()
5) Once the folder "Open_jLUISMR" has been in the directory shown using pwd(), run the following command: include(pwd() * "/Open_jLUISMR/jLUISMR.jl")
6) jLUISMR should open and be ready to use! Please, create an Issue if you find any problems.
- Please, notice that some of the packages may need some specific steps to be added to Julia. Follow the instructions in their webstites.


## References:
- https://juliapackages.com/p/guiappexample
- https://github.com/ModiaSim/Modia.jl
- https://diffeq.sciml.ai/stable/
- https://github.com/JuliaPy/PyPlot.jl
- https://juliagraphics.github.io/Gtk.jl/stable/
I would like to give as much credit as possible to the great people behind the packages and the Julia community.

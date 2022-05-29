#!/usr/bin/env julia
using Modia, Plots, Gtk, Gtk.ShortNames, DelimitedFiles, ModiaResult
import ModiaResult

jLUISMRui = Builder(filename=(@__DIR__) * "/jLUISMR.glade")


#not working yet: jLUISM_variables_tree=jLUISMRui["jLUISM_variables_tree"]
jLUISM_Vars_List_Store = GtkListStore(String, Float64, Float64)
jLUISM_SimVars_Names = GtkListStore(String)
jLUISM_pepe = GtkListStore(Float64)
jLUISM_Results_Length = GtkListStore(Int)

showall(jLUISMRui["jLUISM_Main_window"])

gettext(textview::GtkTextView) = get_gtk_property(textview, :buffer, GtkTextBuffer) |> x -> get_gtk_property(x, :text, AbstractString)

function simulate_function()
	val = eval(Meta.parse(gettext(jLUISMRui["jLUISM_textual_model"])))
	set_gtk_property!(jLUISMRui["jLUISM_debugg_window"], :text, "")
	empty!(jLUISM_Vars_List_Store)

	try
           	instantiatedModeljLUISMR=@instantiateModel(val)
		result=simulate!(instantiatedModeljLUISMR, Tsit5(), stopTime = 10.0, log=true)
		jLUISM_SimVars_Names = signalNames(instantiatedModeljLUISMR)
		jLUISM_SimVars_Names = unique(jLUISM_SimVars_Names)
		
		for i in 1:length(jLUISM_SimVars_Names)
			push!(jLUISM_Vars_List_Store,(jLUISM_SimVars_Names[i],getPlotSignal(instantiatedModeljLUISMR,jLUISM_SimVars_Names[i])[3][1],last(getPlotSignal(instantiatedModeljLUISMR,jLUISM_SimVars_Names[i])[3])))
		end

		#x=result[1,:]
		#xs=x
		#y=result[2,:]
		#ys=y
		#Plots.plot(xs,ys);
		#savefig("C:\\Resairchia\\apepefile.svg");
		#savefig("C:\\Resairchia\\apepefile2.png");
		#writedlm( "C:\\Resairchia\\FileName.csv", (x,y), ',')


		tv = GtkTreeView(GtkTreeModel(jLUISM_Vars_List_Store))
		selection = GAccessor.selection(tv)
		rTxt = GtkCellRendererText()
		rTog = GtkCellRendererToggle()
		c1 = GtkTreeViewColumn("Name", rTxt, Dict([("text",0)]))
		c2 = GtkTreeViewColumn("Initial value", rTxt, Dict([("text",1)]))
		c3 = GtkTreeViewColumn("Ending value", rTxt, Dict([("text",2)]))
		push!(tv, c1, c2, c3)
		signal_connect(selection, "changed") do widget
			if hasselection(selection)
    				currentIt = selected(selection)

    # now you can to something with the selected item
    		#println("Name: ", jLUISM_Vars_List_Store[currentIt,1], " Age: ", jLUISM_Vars_List_Store[currentIt,2], "Length: ")

           	#instantiatedModeljLUISMR=@instantiateModel(val)
		#result=simulate!(instantiatedModeljLUISMR, Tsit5(), stopTime = 10.0, log=true)
#toXs=getPlotSignal(instantiatedModeljLUISMR,"phi")
#toYs=getPlotSignal(instantiatedModeljLUISMR,"w")
				set_gtk_property!(jLUISMRui["jLUISM_debugg_window"], :text, "Simulation completed. Showing results.")
				Plots.plot(getPlotSignal(instantiatedModeljLUISMR,"time")[3],getPlotSignal(instantiatedModeljLUISMR,jLUISM_Vars_List_Store[currentIt,1])[3], label=jLUISM_Vars_List_Store[currentIt,1]);


				savefig("C:\\Resairchia\\apepefile3.png");
		# Double call to deal with a Plots bug "send: no error"
				Plots.gui()
				Plots.gui()
  			end
		end
		win = GtkWindow(tv, "Simulation results. Click on the variable name to plot.")
		showall(win)

      catch e
            println("Error found when attempting to simulate with jLUISMR")
          	rethrow(e)
      end
	set_gtk_property!(jLUISMRui["jLUISM_debugg_window"], :text, "Simulated")
	Plots.gui()

	return nothing
end

function variables_showPlots()
	
tv = GtkTreeView(GtkTreeModel(jLUISM_Vars_List_Store))
selection = GAccessor.selection(tv)
rTxt = GtkCellRendererText()
rTog = GtkCellRendererToggle()
c1 = GtkTreeViewColumn("Name", rTxt, Dict([("text",0)]))
c2 = GtkTreeViewColumn("Initial value", rTxt, Dict([("text",1)]))
c3 = GtkTreeViewColumn("Ending value", rTxt, Dict([("text",2)]))
push!(tv, c1, c2, c3)
signal_connect(selection, "changed") do widget
  if hasselection(selection)
    currentIt = selected(selection)

    # now you can to something with the selected item
    println("Name: ", jLUISM_Vars_List_Store[currentIt,1], " Age: ", jLUISM_Vars_List_Store[currentIt,2], "Length: ")


	
           	#instantiatedModeljLUISMR=@instantiateModel(val)
		#result=simulate!(instantiatedModeljLUISMR, Tsit5(), stopTime = 10.0, log=true)
#toXs=getPlotSignal(instantiatedModeljLUISMR,"phi")
#toYs=getPlotSignal(instantiatedModeljLUISMR,"w")
set_gtk_property!(jLUISMRui["jLUISM_debugg_window"], :text, "g")
		Plots.plot(getPlotSignal(instantiatedModeljLUISMR,"time")[3],getPlotSignal(instantiatedModeljLUISMR,jLUISM_Vars_List_Store[currentIt,1])[3], label=jLUISM_Vars_List_Store[currentIt,1]);


savefig("C:\\Resairchia\\apepefile3.png");
# Double call to deal with a Plots bug "send: no error"
Plots.gui()
Plots.gui()
  end
end
win = GtkWindow(tv, "Simulation results. Click on the variable name to plot.")
showall(win)
end

function instantiate_function()

	val = eval(Meta.parse(gettext(jLUISMRui["jLUISM_textual_model"])))
	try
           	instantiatedModeljLUISMR=@instantiateModel(val)
      catch e
            println("Error found when attempting to instantiate with jLUISMR")
          	rethrow(e)
      end
	set_gtk_property!(jLUISMRui["jLUISM_debugg_window"], :text, "Instantiated!")

	return nothing
end

signal_connect(x -> simulate_function(), jLUISMRui["jLUISMR_simulate"], "clicked")
signal_connect(x -> instantiate_function(), jLUISMRui["jLUISMR_instantiate"], "clicked")


if !isinteractive()
	c = Condition()
	signal_connect(jLUISMRui["jLUISM_Main_window"], :destroy) do widget
		notify(c)
	end
	wait(c)
end

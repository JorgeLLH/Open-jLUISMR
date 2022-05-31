#!/usr/bin/env julia
using Modia, PyPlot, Gtk, Gtk.ShortNames, DelimitedFiles, ModiaResult
import ModiaResult

jLUISMRui = GtkBuilder(filename=(@__DIR__) * "/jLUISMR.glade")


#not working yet: jLUISM_variables_tree=jLUISMRui["jLUISM_variables_tree"]
jLUISM_Vars_List_Store = GtkListStore(String, Float64, Float64)
jLUISM_SimVars_Names = GtkListStore(String)
jLUISM_pepe = GtkListStore(Float64)
jLUISM_Results_Length = GtkListStore(Int)
pygui(true)

showall(jLUISMRui["jLUISM_Main_window"])

gettext(textview::GtkTextView) = get_gtk_property(textview, :buffer, GtkTextBuffer) |> x -> get_gtk_property(x, :text, AbstractString)

function simulate_function()
	val = eval(Meta.parse(gettext(jLUISMRui["jLUISM_textual_model"])))
	set_gtk_property!(jLUISMRui["jLUISM_debugg_window"], :text, "")
	empty!(jLUISM_Vars_List_Store)
	jLUISM_startTime=eval(Meta.parse(gettext(jLUISMRui["jLUISM_start_Time"])))
	if isnothing(jLUISM_startTime)
		jLUISM_startTime=0.0
	end
	jLUISM_stopTime=eval(Meta.parse(gettext(jLUISMRui["jLUISM_stop_Time"])))
	if isnothing(jLUISM_stopTime)
		jLUISM_stopTime=10.0
	end
	jLUISM_interval=eval(Meta.parse(gettext(jLUISMRui["jLUISM_step_Time"])))
	if isnothing(jLUISM_interval)
		jLUISM_interval=(jLUISM_stopTime-jLUISM_startTime)/500
	end
	jLUISM_allow_Simulation=false
	if (jLUISM_startTime<jLUISM_stopTime) & (jLUISM_interval<(jLUISM_stopTime-jLUISM_startTime)) & (0<jLUISM_interval)
		jLUISM_allow_Simulation=true
	end

	try
           	instantiatedModeljLUISMR=@instantiateModel(val)
		result=simulate!(instantiatedModeljLUISMR, Tsit5(), startTime=jLUISM_startTime, stopTime = jLUISM_stopTime, interval=jLUISM_interval, log=true)
		jLUISM_SimVars_Names = signalNames(instantiatedModeljLUISMR)
		jLUISM_SimVars_Names = unique(jLUISM_SimVars_Names)
		for i in 1:length(jLUISM_SimVars_Names)
			push!(jLUISM_Vars_List_Store,(jLUISM_SimVars_Names[i],getPlotSignal(instantiatedModeljLUISMR,jLUISM_SimVars_Names[i])[3][1],last(getPlotSignal(instantiatedModeljLUISMR,jLUISM_SimVars_Names[i])[3])))
		end
		set_gtk_property!(jLUISMRui["jLUISM_debugg_window"], :text, "Simulation completed. Showing results.")
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
    				println("Name: ", jLUISM_Vars_List_Store[currentIt,1], " Initial value: ", jLUISM_Vars_List_Store[currentIt,2], " Ending value: ", jLUISM_Vars_List_Store[currentIt,3])
				PyPlot.plot(getPlotSignal(instantiatedModeljLUISMR,"time")[3],getPlotSignal(instantiatedModeljLUISMR,jLUISM_Vars_List_Store[currentIt,1])[3], label=jLUISM_Vars_List_Store[currentIt,1])
				display(gcf())
  			end
		end
		win = GtkWindow(tv, "Simulation results. Click on the variable name to plot.")
		showall(win)
      	catch e
            println("Error found when attempting to simulate with jLUISMR")
          	rethrow(e)
      	end 
	set_gtk_property!(jLUISMRui["jLUISM_debugg_window"], :text, "Finished")
	return nothing
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

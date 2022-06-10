#!/usr/bin/env julia
using Modia, PyPlot, Gtk, Gtk.ShortNames, DelimitedFiles, ModiaResult
import ModiaResult

jLUISMR_Vars_List_Store = GtkListStore(String, Float64, Float64)
jLUISMR_SimVars_Names = GtkListStore(String)
pygui(true)

mutable struct TextModule
    name::AbstractString
    fileplace::AbstractString

    TextModule() = new("", "")
end

text = TextModule()

jLUISMRui = GtkBuilder(filename=(@__DIR__) * "/jLUISMR.glade")
showall(jLUISMRui["jLUISMR_Main_window"])

writetext!(textview::GtkTextView, s::AbstractString) = get_gtk_property(textview, :buffer, GtkTextBuffer) |> x -> set_gtk_property!(x, :text, s)
gettext(textview::GtkTextView) = get_gtk_property(textview, :buffer, GtkTextBuffer) |> x -> get_gtk_property(x, :text, AbstractString)

textcontent = open(io->read(io, String), pwd() * "/Open_jLUISMR/Resources/WelcomeMessage_jLUISMR.txt")
writetext!(jLUISMRui["jLUISMR_help_TextView"], textcontent)

function simulate_function()
	val = eval(Meta.parse(gettext(jLUISMRui["jLUISMR_textual_model"])))
	set_gtk_property!(jLUISMRui["jLUISMR_debugg_window"], :text, "")
	empty!(jLUISMR_Vars_List_Store)
	jLUISMR_startTime=eval(Meta.parse(gettext(jLUISMRui["jLUISMR_start_Time"])))
	if isnothing(jLUISMR_startTime)
		jLUISMR_startTime=0.0
	end
	jLUISMR_stopTime=eval(Meta.parse(gettext(jLUISMRui["jLUISMR_stop_Time"])))
	if isnothing(jLUISMR_stopTime)
		jLUISMR_stopTime=10.0
	end
	jLUISMR_interval=eval(Meta.parse(gettext(jLUISMRui["jLUISMR_step_Time"])))
	if isnothing(jLUISMR_interval)
		jLUISMR_interval=(jLUISMR_stopTime-jLUISMR_startTime)/500
	end
	jLUISMR_allow_Simulation=false
	if (jLUISMR_startTime<jLUISMR_stopTime) & (jLUISMR_interval<(jLUISMR_stopTime-jLUISMR_startTime)) & (0<jLUISMR_interval)
		jLUISMR_allow_Simulation=true
	end
	try
           	instantiatedModeljLUISMR=@instantiateModel(val)
		result=simulate!(instantiatedModeljLUISMR, eval(Meta.parse(Gtk.bytestring( GAccessor.active_text(jLUISMRui["jLUISMR_solver_test"])))), startTime=jLUISMR_startTime, stopTime = jLUISMR_stopTime, interval=jLUISMR_interval, log=true)
		jLUISMR_SimVars_Names = signalNames(instantiatedModeljLUISMR)
		jLUISMR_SimVars_Names = unique(jLUISMR_SimVars_Names)
		for i in 1:length(jLUISMR_SimVars_Names)
			push!(jLUISMR_Vars_List_Store,(jLUISMR_SimVars_Names[i],getPlotSignal(instantiatedModeljLUISMR,jLUISMR_SimVars_Names[i])[3][1],last(getPlotSignal(instantiatedModeljLUISMR,jLUISMR_SimVars_Names[i])[3])))
		end
		set_gtk_property!(jLUISMRui["jLUISMR_debugg_window"], :text, "Simulation completed. Showing results.")
		tv = GtkTreeView(GtkTreeModel(jLUISMR_Vars_List_Store))
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
    				println("Name: ", jLUISMR_Vars_List_Store[currentIt,1], " Initial value: ", jLUISMR_Vars_List_Store[currentIt,2], " Ending value: ", jLUISMR_Vars_List_Store[currentIt,3])
				PyPlot.plot(getPlotSignal(instantiatedModeljLUISMR,"time")[3],getPlotSignal(instantiatedModeljLUISMR,jLUISMR_Vars_List_Store[currentIt,1])[3], label=jLUISMR_Vars_List_Store[currentIt,1])
				display(gcf())
  			end
		end
		win = GtkWindow(tv, "Simulation results. Click on the variable name to plot.")
		showall(win)
      	catch e
            println("Error found when attempting to simulate with jLUISMR")
          	rethrow(e)
      	end 
	set_gtk_property!(jLUISMRui["jLUISMR_debugg_window"], :text, "Finished")
	return nothing
end
function instantiate_function()
	val = eval(Meta.parse(gettext(jLUISMRui["jLUISMR_textual_model"])))
	try
           	instantiatedModeljLUISMR=@instantiateModel(val)
      catch e
            println("Error found when attempting to instantiate with jLUISMR")
          	rethrow(e)
      end
	set_gtk_property!(jLUISMRui["jLUISMR_debugg_window"], :text, "Instantiated")
	return nothing
end
function load_library()
	include(pwd() * "/Open_jLUISMR/Libraries/Electrical.jl")
	textcontent = open(io->read(io, String), pwd() * "/Open_jLUISMR/Libraries/Electrical.txt")
	writetext!(jLUISMRui["jLUISMR_help_TextView"], textcontent)
	text.name = split(text.fileplace, "/")[end]
	set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)
	set_gtk_property!(jLUISMRui["jLUISMR_debugg_window"], :text, "Electric library loaded")
	return nothing
end


function file_new()
	writetext!(jLUISMRui["jLUISMR_textual_model"], "")
	return nothing
end

function file_open()
    text.fileplace = open_dialog("Open file", jLUISMRui["jLUISMR_Main_window"], ("*.txt", "*",))
    if !isempty(text.fileplace)
        textcontent = open(io->read(io, String), text.fileplace)
        writetext!(jLUISMRui["jLUISMR_textual_model"], textcontent)
        text.name = split(text.fileplace, "/")[end]
        set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)
    end

    return nothing
end

function file_save()
    if isempty(text.name)
        file_save_as()
    else
        textcontent = gettext(jLUISMRui["jLUISMR_textual_model"])
        write(text.fileplace, textcontent)
    end

    return nothing
end

function file_save_as()
    fileplace = save_dialog("Save file")
    if !isempty(fileplace)
        text.fileplace = fileplace
        textcontent = gettext(jLUISMRui["jLUISMR_textual_model"])
        write(text.fileplace, textcontent)
        text.name = split(text.fileplace, "/")[end]
        set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)
    end

    return nothing
end

function help_QStart()
	textcontent = open(io->read(io, String), pwd() * "/Open_jLUISMR/Resources/Quick_Start.txt")
	writetext!(jLUISMRui["jLUISMR_help_TextView"], textcontent)
	text.name = split(text.fileplace, "/")[end]
	set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)

    return nothing
end

function help_SolverGuide()
	textcontent = open(io->read(io, String), pwd() * "/Open_jLUISMR/Resources/Solver_Guide.txt")
	writetext!(jLUISMRui["jLUISMR_help_TextView"], textcontent)
	text.name = split(text.fileplace, "/")[end]
	set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)

    return nothing
end

function help_License()
	textcontent = open(io->read(io, String), pwd() * "/Open_jLUISMR/LICENSE.txt")
	writetext!(jLUISMRui["jLUISMR_help_TextView"], textcontent)
	text.name = split(text.fileplace, "/")[end]
	set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)

    return nothing
end

function help_About()
	textcontent = open(io->read(io, String), pwd() * "/Open_jLUISMR/Resources/About.txt")
	writetext!(jLUISMRui["jLUISMR_help_TextView"], textcontent)
	text.name = split(text.fileplace, "/")[end]
	set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)

    return nothing
end

signal_connect(x -> file_open(), jLUISMRui["jLUISMR_Open_ToolButton"], "clicked")
signal_connect(x -> file_save(), jLUISMRui["jLUISMR_Save_ToolButton"], "clicked")
signal_connect(x -> instantiate_function(), jLUISMRui["jLUISMR_instantiate"], "clicked")
signal_connect(x -> simulate_function(), jLUISMRui["jLUISMR_simulate"], "clicked")
signal_connect(x -> help_QStart(), jLUISMRui["jLUISMR_QStart_Button"], "clicked")
signal_connect(x -> load_library(), jLUISMRui["jLUISMR_Library_Electric"], "clicked")
signal_connect((x,y)->file_new(), jLUISMRui["jLUISMR_file_new"], :activate, Nothing, (), false)
signal_connect((x,y)->file_open(), jLUISMRui["jLUISMR_file_open"], :activate, Nothing, (), false)
signal_connect((x,y)->file_save(), jLUISMRui["jLUISMR_file_save"], :activate, Nothing, (), false)
signal_connect((x,y)->file_save_as(), jLUISMRui["jLUISMR_file_saveas"], :activate, Nothing, (), false)
signal_connect((x,y)->exit(), jLUISMRui["jLUISMR_file_quit"], :activate, Nothing, (), false)
signal_connect((x,y)->help_QStart(), jLUISMRui["jLUISMR_help_QStart"], :activate, Nothing, (), false)
signal_connect((x,y)->help_SolverGuide(), jLUISMRui["jLUISMR_help_SolverGuide"], :activate, Nothing, (), false)
signal_connect((x,y)->help_License(), jLUISMRui["jLUISMR_help_License"], :activate, Nothing, (), false)
signal_connect((x,y)->help_About(), jLUISMRui["jLUISMR_help_About"], :activate, Nothing, (), false)
if !isinteractive()
	c = Condition()
	signal_connect(jLUISMRui["jLUISMR_Main_window"], :destroy) do widget
		notify(c)
	end
	wait(c)
end
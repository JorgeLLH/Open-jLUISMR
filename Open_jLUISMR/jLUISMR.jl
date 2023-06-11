#!/usr/bin/env julia
using Modia, Plots, Gtk, Gtk.ShortNames
 
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

#---------------------------Main function for simulation -------------------------
function simulate_function()
	jLUISMR_Vars_List_Store = GtkListStore(String, Float64, Float64)
	jLUISMR_SimVars_Names = GtkListStore(String)
	#val = eval(Meta.parse(gettext(jLUISMRui["jLUISMR_textual_model"])))
	jLUISMR_pred_plot_pattern=r"pdPlot<<.+>>"
	val = gettext(jLUISMRui["jLUISMR_textual_model"])
	jLUISMR_pred_plots = match(jLUISMR_pred_plot_pattern, val)
	val = replace(val, jLUISMR_pred_plot_pattern => "")
	val = eval(Meta.parse(val))
	jLUISMR_pred_plots=(jLUISMR_pred_plots === nothing) ? "0" : replace(jLUISMR_pred_plots.match, r"pdPlot<<" => "");
	jLUISMR_pred_plots=replace(jLUISMR_pred_plots, r">>" => "");
	store_string=split(jLUISMR_pred_plots, ";");
	store_string_vars=split(store_string[1], ",")#(length(jLUISMR_SimVars_Names) > 0) ? split(store_string[1], ",") : 0;

	set_gtk_property!(jLUISMRui["jLUISMR_debugg_window"], :text, "")

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
		if (length(store_string) == 3) && store_string[3]=="Animate" #store_string[3] evaluated only if length is enough
			predefined_MP4_Plots(instantiatedModeljLUISMR,String(string(store_string_vars[1])),String(string(store_string_vars[2])),String(string(store_string_vars[3])),String(string(store_string[2])),jLUISMR_interval)
		elseif (length(store_string) == 3) && store_string[3]=="Plots" #store_string[3] evaluated only if length is enough
			predefined_plot_Plots(instantiatedModeljLUISMR,String(string(store_string_vars[1])),String(string(store_string_vars[2])),String(string(store_string[2])))
		elseif (length(store_string) == 2)
			predefined_plot_Plots(instantiatedModeljLUISMR,String(string(store_string_vars[1])),String(string(store_string_vars[2])),String(string(store_string[2])))
		elseif (length(store_string) == 1) && (length(store_string_vars) > 1)
			predefined_plot_Plots(instantiatedModeljLUISMR,String(string(store_string_vars[1])),String(string(store_string_vars[2])))
		end
		jLUISMR_SimVars_Names = SignalTables.getSignalNames(instantiatedModeljLUISMR)
		for i in 1:length(jLUISMR_SimVars_Names)
			if get(SignalTables.getSignal(instantiatedModeljLUISMR, jLUISMR_SimVars_Names[i]), :_class, 0) ==:Var
				push!(jLUISMR_Vars_List_Store,(jLUISMR_SimVars_Names[i], SignalTables.getValues(instantiatedModeljLUISMR,jLUISMR_SimVars_Names[i])[1],last(getValues(instantiatedModeljLUISMR,jLUISMR_SimVars_Names[i]))))
			end
		end
		set_gtk_property!(jLUISMRui["jLUISMR_debugg_window"], :text, "Simulation completed. Showing results.")
		if get_gtk_property(jLUISMRui["jLUISMR_checkB_SaveResul"], "active", Bool)
			writeSignalTable("jLUISMR_Modia_simulation_results.json", instantiatedModeljLUISMR, indent=2, log=true)
		end
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
				Plots.plot(getValues(instantiatedModeljLUISMR,"time"), getValues(instantiatedModeljLUISMR,jLUISMR_Vars_List_Store[currentIt,1]), label=(jLUISMR_Vars_List_Store[currentIt,1]*" ["*get(SignalTables.getSignal(instantiatedModeljLUISMR, jLUISMR_Vars_List_Store[currentIt,1]), :unit, 0)*"]"))
				gui()
  			end
		end
		push!(jLUISMRui["resultBox"], tv)
		push!(jLUISMRui["jLUISMR_Main_window"], jLUISMRui["resultBox"])
		showall(jLUISMRui["jLUISMR_Main_window"])
      	catch e
            println("Error found when attempting to simulate with jLUISMR")
          	rethrow(e)
      	end 
	return nothing
end

#---------------------------Instantiate function for model validation -------------------------
function instantiate_function()
	#val = eval(Meta.parse(gettext(jLUISMRui["jLUISMR_textual_model"])))
	val = gettext(jLUISMRui["jLUISMR_textual_model"])
	val = replace(val, r"pdPlot<<.+>>" => "")
	val = eval(Meta.parse(val))
	try
           	instantiatedModeljLUISMR=@instantiateModel(val)
      catch e
            println("Error found when attempting to instantiate with jLUISMR")
          	rethrow(e)
      end
	set_gtk_property!(jLUISMRui["jLUISMR_debugg_window"], :text, "Instantiated")
	return nothing
end

#---------------------------Library loading function for component modeling TO BE UPDATED -------------------------
function load_library()
	#include(pwd() * "/Open_jLUISMR/Libraries/Electrical.jl")
	include("$(Modia.modelsPath)/Electric.jl")
	textcontent = open(io->read(io, String), pwd() * "/Open_jLUISMR/Libraries/Electrical.txt")
	writetext!(jLUISMRui["jLUISMR_help_TextView"], textcontent)
	text.name = split(text.fileplace, "/")[end]
	set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)
	set_gtk_property!(jLUISMRui["jLUISMR_debugg_window"], :text, "Electric library loaded")
	return nothing
end

#---------------------------New model function -------------------------
function file_new()
	writetext!(jLUISMRui["jLUISMR_textual_model"], "")
	return nothing
end

#---------------------------Open file with model function -------------------------
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

#---------------------------Save model function -------------------------
function file_save()
    if isempty(text.name)
        file_save_as()
    else
        textcontent = gettext(jLUISMRui["jLUISMR_textual_model"])
        write(text.fileplace, textcontent)
    end

    return nothing
end

#---------------------------Save as model function -------------------------
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

#---------------------------Load help function -------------------------
function help_QStart()
	textcontent = open(io->read(io, String), pwd() * "/Open_jLUISMR/Resources/Quick_Start.txt")
	writetext!(jLUISMRui["jLUISMR_help_TextView"], textcontent)
	text.name = split(text.fileplace, "/")[end]
	set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)

    return nothing
end

#---------------------------Load solver help function -------------------------
function help_SolverGuide()
	textcontent = open(io->read(io, String), pwd() * "/Open_jLUISMR/Resources/Solver_Guide.txt")
	writetext!(jLUISMRui["jLUISMR_help_TextView"], textcontent)
	text.name = split(text.fileplace, "/")[end]
	set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)

    return nothing
end

#---------------------------Load license function -------------------------
function help_License()
	textcontent = open(io->read(io, String), pwd() * "/Open_jLUISMR/LICENSE.txt")
	writetext!(jLUISMRui["jLUISMR_help_TextView"], textcontent)
	text.name = split(text.fileplace, "/")[end]
	set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)

    return nothing
end

#---------------------------Load about function -------------------------
function help_About()
	textcontent = open(io->read(io, String), pwd() * "/Open_jLUISMR/Resources/About.txt")
	writetext!(jLUISMRui["jLUISMR_help_TextView"], textcontent)
	text.name = split(text.fileplace, "/")[end]
	set_gtk_property!(jLUISMRui["jLUISMR_Main_window"], :title, text.name)

    return nothing
end

#---------------------------Predefined plot function Plots-------------------------
function predefined_plot_Plots(instantiatedModeljLUISMR,predef_var1,predef_var2,predef_title)
	Plots.plot(getValues(instantiatedModeljLUISMR,predef_var1), getValues(instantiatedModeljLUISMR,predef_var2), title=predef_title, label=(predef_var2*" ["*get(SignalTables.getSignal(instantiatedModeljLUISMR, predef_var2), :unit, 0)*"]"))
	gui()
	return nothing
end

#---------------------------Predefined plot function Makie DEPRECATED-------------------------
function predefined_plot_Makie(instantiatedModeljLUISMR,predef_var1,predef_var2,predef_title)
	#GLMakie.activate!();
    	#fig = Figure(; resolution=(400, 400));
    	#ax1 = Axis3(fig[1, 1];title=predef_title, aspect=(1, 1, 1), perspectiveness=0.5);
	#GLMakie.lines!(ax1, getValues(instantiatedModeljLUISMR,predef_var1), getValues(instantiatedModeljLUISMR,predef_var2));
    	#GLMakie.display(fig)
	#return nothing
end

#---------------------------Predefined PlotsMP4 function Plots-------------------------
function predefined_MP4_Plots(instantiatedModeljLUISMR,predef_var1,predef_var2,predef_var3,predef_title,jLUISMR_interval)
	x_LUISMR_MP4=getValues(instantiatedModeljLUISMR,predef_var1)
	y_LUISMR_MP4=getValues(instantiatedModeljLUISMR,predef_var2)
	z_LUISMR_MP4=getValues(instantiatedModeljLUISMR,predef_var3)
	jLUISMR_fps=floor(Int, 1/jLUISMR_interval)
	LUISMR_MP4 = Plots.plot3d(
           1,
           xlim = (minimum(x_LUISMR_MP4), maximum(x_LUISMR_MP4)),
           ylim = (minimum(y_LUISMR_MP4), maximum(y_LUISMR_MP4)),
           zlim = (minimum(z_LUISMR_MP4), maximum(z_LUISMR_MP4)),
           title = predef_title,
           legend = false,
           marker = 2,
       )
	anim = @animate for i in 1: length(x_LUISMR_MP4)    
	push!(LUISMR_MP4,x_LUISMR_MP4[i], y_LUISMR_MP4[i], z_LUISMR_MP4[i])  
	end every 1;
	gif(anim,"LUISMR_MP4.mp4", fps = jLUISMR_fps);
	return nothing
end

#---------------------------Buttons and clicked options -------------------------
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

#---------------------------Main window -------------------------
if !isinteractive()
	c = Condition()
	signal_connect(jLUISMRui["jLUISMR_Main_window"], :destroy) do widget
		notify(c)
	end
	@async Gtk.gtk_main()
	wait(c)
end

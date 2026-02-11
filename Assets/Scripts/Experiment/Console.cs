/* Console.cs
 * Text console interface for researcher commands and debugging.
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * SPDX-License-Identifier: MIT
 */

using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class SAOLConsole : MonoBehaviour
{
    public bool visible = false;
    public bool appeared = false;

    public GUISkin skin;

    // Command History
    private List<string> _history = new List<string>();
    private List<string> _results = new List<string>();
    private string command = "";


    // UI Dimensions
    private const long width_px = 640;
    private const long height_px = 480;
    private readonly long l_border_px = (Screen.width - width_px) / 2L;
    private readonly long t_border_px = (Screen.height - height_px) / 2;
    private Vector2 scroll = new Vector2();
    

    // Connected Components
    public PCRM experiment;
    private InputAction toggleAction;

    void Awake()
    {
        toggleAction = new InputAction("SAOL Open Console");
        toggleAction.AddBinding("<Keyboard>/escape");
        toggleAction.AddBinding("<Gamepad>/start");
        toggleAction.started += ctx => toggle_visibility();
        toggleAction.Enable();
    }

    void OnGUI()
    {   
        if (!visible)
            return;

        GUI.skin = skin;

        float line_px = GUI.skin.label.lineHeight; // Properties can only be accessed within OnGUI

        // Overlay and Title
        GUI.Box (
            new Rect(l_border_px, t_border_px, width_px, height_px),
            "SAOL3D - Research Experiment Console - " + PCRM.appname + " " + PCRM.version
        );

        // FPS and Diagnostics
        GUI.Label(
            new Rect(l_border_px+1, t_border_px+line_px+1, width_px-2, line_px*2),
            String.Format("{0,5:F1}fps  {1,8:F3}s application runtime", 1/Time.deltaTime, Time.realtimeSinceStartup)
        );

        // Scroll Box for History
        scroll = GUI.BeginScrollView(
            new Rect(l_border_px+2, t_border_px+line_px*3+2, width_px-4, height_px-(line_px*5+4)),
            scroll,
            new Rect (0, 0, width_px-25, line_px*2*_history.Count+line_px),
            false,
            true
        );
    
        string message = ""; 
        for (int j = 0; j<_history.Count; j++) 
            message += _history[j] + "\n" + _results[j] + "\n";

        GUI.TextArea(
            new Rect(0,0,width_px-25,line_px*2*_history.Count+line_px),
            message
        );

        GUI.EndScrollView();

        // Handle Commands
        // Per https://docs.unity3d.com/ScriptReference/GUI.SetNextControlName.html
        if (GUI.GetNameOfFocusedControl() == "command" && Event.current.type == EventType.KeyDown){

            if (Event.current.keyCode == KeyCode.Return) {
                string timestamp = DateTime.UtcNow.ToString("yyyyMMdd'T'HHmmss'Z'");
                _history.Add(timestamp+": " + command);

                try {
                    _results.Add(handle_command(command));
                } catch (Exception e)
                {
                    Debug.LogError(e);
                    _results.Add(e.Message);
                }
                
                scroll.y = line_px*2*_history.Count+line_px;

                command = "";
                Event.current.Use();
            }
            
            if (Event.current.keyCode == KeyCode.UpArrow) {
                if (_history.Count > 0)
                    command = _history[_history.Count-1].Substring(18);
                Event.current.Use();
            } 
        }

        GUI.SetNextControlName("command");
        command = GUI.TextField(
            new Rect (l_border_px+1, t_border_px + height_px - line_px*2 - 1, width_px-2, line_px*2),
            command,
            80
        );

        if (appeared) {
            GUI.FocusControl("command");
            appeared = false;
        }
    }

    string handle_command(string cmdline)
    {

        string[] args = cmdline.Split(" ");

        switch (args[0])
        {
            case "debug":
                return experiment.ToString();
            
            case "demo":
                return experiment.cmd_demo();

            case "help":
                return "Available commands: debug, demo, help, load-stim, load-order, save, start, stop, quit.";
            
            case "load-stim":
                if (args.Length != 3)
                    return "Requires two arguments: file and position.";
                
                return experiment.cmd_load_stimulus(args[1], uint.Parse(args[2]));
            
            case "load-order":
                if (args.Length != 2)
                    return "Requires second argument.";

                return experiment.cmd_load_order(args[1]);


            case "save":

                string timestamp = DateTime.UtcNow.ToString("yyyyMMdd'T'HHmmss'Z'");
                string filename  = "PoseData_" + timestamp + ".tsv.gz";

                if (args.Length > 1)
                    filename = args[1];

                return experiment.cmd_save(filename);;
            
            case "start":
                return experiment.cmd_start();

            case "stop":
                return experiment.cmd_stop();

            case "quit":
                Application.Quit();
                return "Shutting down."; // Technically this is unreachable.
            
            // Undocumented test commands.
            case "test-data":
                return experiment.cmd_test_data();

            case "test-stim":
                return experiment.cmd_test_stim();
            
            case "test-clear":
                return experiment.cmd_test_clear_stim();
            
            case "test-reset":
                return experiment.cmd_test_reset();

            default:
                return "Improper command.";
        }
    }

    public void toggle_visibility()
    {
        visible = !visible;
        appeared = visible;
    }

}
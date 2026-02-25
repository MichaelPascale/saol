/* Experiment.cs
 * Generic experiment management class.
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * SPDX-License-Identifier: MIT
 */

using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public abstract class SAOLExperiment : MonoBehaviour
{
    public SAOLPlayer player;
    public SAOLConsole console;
    public SAOLOverlay overlay;

    public enum Mode { Uninitialized, Ready, Running, Stopped }
    protected Mode mode;
    protected uint trial;
    protected uint n_trials;
    protected DateTime t_init;
    protected DateTime t_trial;
    protected double elapsed_s;
    protected double elapsed_trial_s;

    protected string session_data_dir;

    public void Start()
    {
        session_data_dir = Application.persistentDataPath;
    }
    public void Update()
    {
        if (mode != Mode.Running)
            return;

        elapsed_s = DateTime.Now.Subtract(t_init).TotalSeconds;
        elapsed_trial_s = DateTime.Now.Subtract(t_trial).TotalSeconds;
        log();
    }

    protected void onstart()
    {
        if (mode != Mode.Ready)
            throw new InvalidOperationException("The experiment is not in a ready state.");
        
        trial = 0;
        mode = Mode.Running;
        t_init = DateTime.Now;
        elapsed_s = 0;
        
        t_trial = DateTime.Now;
        elapsed_trial_s = 0;

        console.toggle_visibility();

        setup_session();
    }

    protected void onstop()
    {
        mode = Mode.Stopped;
        StopAllCoroutines();
    }

    protected void next_trial()
    {
        if (trial > 0)
            end_trial();

        trial++;
        overlay.clear();

        if (trial > n_trials) {
            end_session();
            return;
        }

        t_trial = DateTime.Now;
        elapsed_trial_s = 0;

        setup_trial();
    }

    protected IEnumerator wait_then_execute(Action action, float time_s)
    {
        yield return new WaitForSecondsRealtime(time_s);
        action();
    }

    protected IEnumerator wait_for_space(Action action, string message = "Press start to begin.")
    {
        overlay.clear();
        overlay.text(message);
        overlay.show();
        yield return new WaitUntil(() => Keyboard.current.spaceKey.wasPressedThisFrame || (Gamepad.current != null ? Gamepad.current.startButton.wasPressedThisFrame : false));

        overlay.clear();
        action();
    }

    public abstract string cmd_save(string path);
    public abstract string cmd_start();
    public abstract string cmd_stop();

    protected abstract void setup_session();
    protected abstract void setup_trial();
    protected abstract void end_trial();
    protected abstract void end_session();
    protected abstract void log();

    public override string ToString()
    {
        return mode == Mode.Running ? $"Experiment began at {t_init} (trial {trial}, {DateTime.Now-t_init}s elapsed)." : "No experiment running.";
    }
}
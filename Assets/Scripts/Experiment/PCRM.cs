/* PCRM.cs
 * Perceptual Curiosity in the Radial Maze Task
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * SPDX-License-Identifier: MIT
 */

using UnityEngine;

public class PCRM : SAOLExperiment
{
    private OrderTable order;
    public const uint ARMS = 8;
    public const uint SIDES = 19;
    public const float STIM_Y = 2;

    private StimulusImageInner[ARMS] stimuli_inner;
    private StimulusImageOuter[ARMS] stimuli_outer; 

    // Start the experiment session. Triggered from the command line implemented in Console.
    public override string cmd_start()
    {
        if (order.uniqueID is null)
            return "A trial order file has not been loaded.";

        if (mode == Mode.Uninitialized)
            return "An experiment has not been initialized";
        
        start();

        return "Began at " + t_init + ".";
    }

    // Stop the experiment session.
    public override string cmd_stop()
    {
        if (mode != Mode.Running)
            return "An experiment was not running.";

        stop();

        return "Stopped.";
    }
    
    // Load a .TSV containing the trial orderings.
    // Columns should be trial, arm, blur, uniqueID, sigma.
    // NOTE: This assumes that the rows are sorted by trial and arm. It performs no checks.
    public string cmd_load_order(string file)
    {
        string[] lines = File.ReadAllLines(file);
        
        string[] names = lines[0].Split('\t');
        Debug.Log("loaded file with headers: " + string.Join(' ', names));

        int n = lines.Length - 1;    // Excluding the header row.
        if (lines.Last() == "") n--; // Excluding an empty last line.

        order.trial     = new int[n];
        order.arm       = new int[n];
        order.blurlevel = new int[n];
        order.uniqueID  = new string[n];
        order.sigma     = new float[n];

        for (int i=0;i<n;i++)
        {
            string[] fields = lines[i+1].Split('\t');
            order.trial[i]        = int.Parse(fields[0]);
            order.arm[i]          = int.Parse(fields[1]);
            order.blurlevel[i]    = int.Parse(fields[2]);
            order.uniqueID[i]     = fields[3];
            order.sigma[i]        = float.Parse(fields[4]);
        }

        order.n_trials = order.trial[n-1];
        order.n_arms   = order.arm[n-1];
        
        return "Loaded order file.";
    }

    // Place a stimulus image at a particular position.
    public string cmd_load_stimulus(string file, int position)
    {
        stimuli_inner[position] = null; // TODO: Is a nulled item garbage-collected? Are corresponding GameObjects desroyed?
        return "Loaded stimulus.";
    }

    private void place_stimuli()
    {
        
    }

};

public struct OrderTable
{
    public int n_trials;
    public int n_arms;
    public int[] trial;
    public int[] arm;
    public int[] blurlevel;
    public string[] uniqueID;
    public float[] sigma;
};

public abstract class StimulusImage
{
    public StimulusImage(string filename, uint position)
    {
        
    }

    public abstract Vector3 get_coordinates(uint position);
    public abstract float get_orientation_y(uint position);
};

// Stimuli at the arm enterances (blurred).
public class StimulusImageInner : StimulusImage
{
    public override Vector3 get_coordinates(uint position)
    {
        if (position > ARMS)
            throw new  ArgumentOutOfRangeException("position", $"Position of {position} exceeds the number of arms (8).");

        // if (position == 0)
        //     return new Vector3(0, STIM_Y, 0);

        return new Vector3(
            (float)Sin(4 * PI * position / 18) / 2 * 15,
            STIM_Y,
            (float)Cos(4 * PI * position / 18) / 2 * 15
        );
    }

    public override float get_orientation_y(uint position)
    {
        return 40 * (position - 1);
    }
};

// Stimuli at the arm ends (clarified).
public class StimulusImageOuter : StimulusImage
{
    public override Vector3 get_coordinates(uint position)
    {
        if (position > ARMS)
            throw new  ArgumentOutOfRangeException(nameof(position), $"Position of {position} exceeds the number of arms (8).");

        return new Vector3(
            (float)Sin(4 * PI * position / 18) / 2 * 15 * 5.5f + (float)(Cos(4 * PI * position / 18) * 1.45 * Sin(PI / 18) * 15),
            STIM_Y,
            (float)Cos(4 * PI * position / 18) / 2 * 15 * 5.5f - (float)(Sin(4 * PI * position / 18) * 1.45 * Sin(PI / 18) * 15)
        );
    }

    public override float get_orientation_y(uint position)
    {
        return 40 * (position - 1) + 90;
    }
};

/* PCRM.cs
 * Perceptual Curiosity in the Radial Maze Task
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * SPDX-License-Identifier: MIT
 */

using System;
using System.IO;
using System.Text;
using System.IO.Compression;
using System.Collections.Generic;

using UnityEngine;
using System.Collections;

public class PCRM : SAOLExperiment
{
    public const string appname = "PCRM";
    public const string version = "0.1.0";
    private OrderTable order;

    public EffortfulControl control;
    public const uint ARMS = 8;
    public const int PREALLOC_SIZE_TRAJ = 216000; // 60Hz for 1h.

    public string stimuli_path; // Path to directory.

    private readonly PCRMStim[] stimuli_inner = new PCRMStim[ARMS];
    private readonly PCRMStim[] stimuli_outer = new PCRMStim[ARMS]; // FIXME: Outer.

    private List<PositionData> trajectory_data = new List<PositionData>(PREALLOC_SIZE_TRAJ);

    // Start the experiment session. Triggered from the command line implemented in Console.
    public override string cmd_start()
    {
        if (order.uniqueID is null)
            return "A trial order file has not been loaded.";

        onstart();

        return "Began at " + t_init + ".";
    }

    // Stop the experiment session.
    public override string cmd_stop()
    {
        if (mode != Mode.Running)
            return "An experiment was not running.";

        onstop();
        control.stop_record();
        player.unpause();
        control.isPaused = false;
        
        return "Stopped.";
    }

    // Save the session's data.
    public override string cmd_save(string path)
    {
        if (trajectory_data.Count == 0)
            return "No data to save.";

        write_data(path);
        control.save("effort" + DateTime.UtcNow.ToString("yyyyMMdd'T'HHmmss'Z'") + ".tsv.gz");

        return $"Saved to '{path}'";
    }
    
    // Load a .TSV containing the trial orderings.
    // Columns should be trial, arm, blur, uniqueID, sigma.
    // NOTE: This assumes that the rows are sorted by trial and arm. It performs no checks.
    public string cmd_load_order(string file)
    {
        string[] lines = File.ReadAllLines(Path.Join(stimuli_path, "Parameters", file));
        
        string[] names = lines[0].Split('\t');
        Debug.Log("loaded file with headers: " + string.Join(' ', names));

        int n = lines.Length - 1;    // Excluding the header row.
        if (lines[n] == "") n--; // Excluding an empty last line.

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

            // Check that the image exists.
            string imgpath = Path.Join(stimuli_path, $"{fields[3]}_{fields[2]}.jpg");
            if (!File.Exists(imgpath))
                throw new FileNotFoundException($"Could not locate {imgpath} needed by order file {file}");
        }

        order.n_trials = order.trial[n-1];
        order.n_arms   = order.arm[n-1];

        n_trials = (uint) order.n_trials;

        mode = Mode.Ready;
        
        return "Loaded order file.";
    }

    public string cmd_demo()
    {
        clear_stimuli();
        for (uint i = 0; i < ARMS; i++)
        {
            stimuli_inner[i] = new PCRMStim(i+1, $"Assets/Textures/SVLO/00{i+1}.png", blur: 10);
            stimuli_outer[i] = new PCRMStimOuter(i+1, $"Assets/Textures/SVLO/00{i+1}.png");
        }

        return "SVLO demo loaded.";
    }

    // Place a stimulus image at a particular position.
    public string cmd_load_stimulus(string file, uint position)
    {
        if (stimuli_inner[position - 1] != null)
            stimuli_inner[position - 1].Dispose();
        
        stimuli_inner[position - 1] = new PCRMStim(position, file);
        return "Loaded stimulus.";
    }

    // Events occuring at the start and end of each trial and session.
    // These are called by the base class and should not invoke any 
    // base class methods.
    protected override void setup_session()
    {
        trajectory_data.Clear();
        control.record();
        clear_stimuli();
        StartCoroutine(wait_for_space(next_trial));
    }

    protected override void setup_trial()
    {
        Debug.Log("Beginning trial " + trial + " at " + Time.realtimeSinceStartup);
        overlay.text("This is the next floor of the museum.");
        overlay.show();

        control.isPaused = true;
        player.reset();
        player.pause();

        // Event durations.
        float ts_ins1 =  2;
        float ts_rota = 18;
        float ts_ins2 =  2;

        float ts_move = 40;

        float ts_fade =  5;
        float ts_ins3 =  2;
        //      total = 69 (42 min for 40 trials)

        // FIXME: Loading the stimuli takes time. Eliminate this delay.
        // Here during the setup is the safest time to block.
        float dbt = Time.realtimeSinceStartup;
        place_stimuli();
        Debug.Log("Loaded stimuli in " + (Time.realtimeSinceStartup - dbt) + " seconds.");
         
        dbt = Time.realtimeSinceStartup;
        // Schedule events that occur within the trial.
        StartCoroutine(wait_then_execute(
            ()=>{
                overlay.clear();
                overlay.hide();
                StartCoroutine(rotate_player(1)); // should take 18 seconds
            },
            ts_ins1
        ));

        StartCoroutine(wait_then_execute(
            ()=>{
                overlay.clear();
                overlay.text("You may spend forty seconds here.");
                overlay.show();
            },
            ts_ins1 + ts_rota
        ));

        StartCoroutine(wait_then_execute(
            ()=>{
                overlay.clear();
                overlay.hide();
                player.unpause(); // unpause the player
                control.isPaused = false;
            },
            ts_ins1 + ts_rota + ts_ins2
        ));

        // Allow the player to move freely for ts_move seconds; then...
        StartCoroutine(wait_then_execute(
            ()=>{
                overlay.fadein(ts_fade);
            },
            ts_ins1 + ts_rota + ts_ins2 + ts_move
        ));

        StartCoroutine(wait_then_execute(
            ()=>{
                control.isPaused = true;
                player.pause();
                overlay.text("Time is up.");
            },
            ts_ins1 + ts_rota + ts_ins2 + ts_move + ts_fade
        ));

        StartCoroutine(wait_then_execute(
            next_trial,
            ts_ins1 + ts_rota + ts_ins2 + ts_move + ts_fade + ts_ins3
        ));

        Debug.Log("Scheduled trial events in " + (Time.realtimeSinceStartup - dbt) + " seconds.");
    }

    protected override void end_trial()
    {
        clear_stimuli();
        Debug.Log("Trial " + trial + " completed in " + elapsed_trial_s + " seconds.");
    }

    protected override void end_session()
    {
        overlay.text("All floors complete.", Color.green);
        overlay.show();
        control.stop_record();
        onstop();
    }

    protected override void log()
    {
        Vector3 p = player.get_position();
        trajectory_data.Add(new PositionData(trial, Time.realtimeSinceStartup, p.x, p.z, player.get_heading()));
    }

    // Move the player through the forced rotation to face each arm at the beginning of the trial.
    private IEnumerator rotate_player(float time_s_each)
    {
        // Go backwards, alternating each trial.
        float counter = -1 + 2 * (trial % 2);

        for (int i = 0; i <= ARMS; i++) {
            // FIXME: Empirically there is a mean error of +60ms per turn, accumulating to nearly a second.
            yield return new WaitForSecondsRealtime(time_s_each);

            float dbt = Time.realtimeSinceStartup;
            float elapsed = 0;

            while (elapsed < time_s_each) // NOTE: The rotation and look duration are the same.
            {
                elapsed += Time.unscaledDeltaTime;
                float y_rot = Mathf.LerpAngle(i*counter*40, (i+1)*counter*40, elapsed/time_s_each);
                player.look(new Vector3(0, y_rot, 0));
                yield return null;
            }

            Debug.Log("Rotation " + i + " completed in " + (Time.realtimeSinceStartup - dbt) + " seconds.");

            player.look(new Vector3(0, (i+1)*counter*40, 0));            
        }
    }

    private void place_stimuli()
    {
        clear_stimuli();
        for (uint i = 0; i < ARMS; i++)
        {
            uint j = get_stim_index(trial, i+1);
            string path = Path.Join(stimuli_path, $"{order.uniqueID[j]}.jpg");
            stimuli_inner[i] = new PCRMStim(i+1, path, blur: order.sigma[j]);
            stimuli_outer[i] = new PCRMStimOuter(i+1, path);
        }
    }

    private void clear_stimuli()
    {
        for (uint i = 0; i < ARMS; i++){
            if (stimuli_inner[i] != null)
            {
                stimuli_inner[i].Dispose();
                stimuli_inner[i] = null;
            }
            if (stimuli_outer[i] != null)
            {
                stimuli_outer[i].Dispose();
                stimuli_outer[i] = null;
            }
        }
    }

    public string cmd_test_data()
    {
        for (int i=0; i < (PREALLOC_SIZE_TRAJ * 3.5); i++)
        trajectory_data.Add(new PositionData(1,0,2f,2f,90f));
        return "Added fake records to test save functions.";
    }

    public string cmd_test_stim()
    {
        for (uint i = 1; i <= ARMS; i++)
        {
            stimuli_inner[i-1] = new PCRMStim(i, $"Assets/Textures/SVLO/00{i}.png");
            stimuli_outer[i-1] = new PCRMStimOuter(i, $"Assets/Textures/SVLO/01{i}.png");
            
        }
        return "Loaded SVLO 1-8 as a test.";
    }

    public string cmd_test_clear_stim()
    {
        clear_stimuli();
        return "Cleared stimuli.";
    }

    public string cmd_test_reset()
    {
        // FIXME: The reset method does not go to the right position.
        player.reset();
        return "Reset player position.";
    }

    // TODO: implement test for controlling overlay.

    private void write_data(string path)
    {
        if (!path.EndsWith(".tsv.gz"))
            throw new ArgumentOutOfRangeException("Provided filename must have extension 'tsv.gz'.");

        using (FileStream stream = File.Create(Path.Combine(Application.persistentDataPath, path)))
        using (GZipStream compressor = new GZipStream(stream, System.IO.Compression.CompressionLevel.Optimal))
        using (StreamWriter writer = new StreamWriter(compressor, Encoding.UTF8))
        {
            writer.WriteLine("trial\ttime\tx\tz\theading");
            foreach (var datapoint in trajectory_data)
                writer.WriteLine(datapoint);
        }

        return;
    }

    private uint get_stim_index(uint trial, uint arm)
    {
        if (order.uniqueID is null)
            throw new InvalidOperationException("A trial order file has not been loaded.");

        if (trial > order.n_trials || trial == 0)
            throw new  ArgumentOutOfRangeException("trial");

        if (arm > order.n_arms || arm == 0)
            throw new  ArgumentOutOfRangeException("arm");

        uint i = (trial - 1) * ARMS + (arm - 1);
        if (order.trial[i] != trial || order.arm[i] != arm)
            throw new InvalidDataException("The order file does not contain the expected entries.");

        return i;
    }

    // NOTE: This is deprecated in favor of direct table lookup with the above get_stim_index().
    private string get_image_path(uint trial, uint arm, bool clear = false)
    {
        if (order.uniqueID is null)
            throw new InvalidOperationException("A trial order file has not been loaded.");

        if (trial > order.n_trials)
            throw new  ArgumentOutOfRangeException("trial");

        if (arm > order.n_arms)
            throw new  ArgumentOutOfRangeException("arm");

        // TODO: Could use a different data structure for faster lookup.
        for (uint i = 0; i < order.trial.Length; i++)
        {
            if (order.trial[i] != trial)
                continue;

            if (order.arm[i] != arm)
                continue;
            
            if (clear)
                return Path.Join(stimuli_path, $"{order.uniqueID[i]}.jpg");

            return Path.Join(stimuli_path, $"{order.uniqueID[i]}_{order.blurlevel[i]}.jpg");
        }

        throw new  KeyNotFoundException($"Could not find a row in the order table matching trial {trial}, arm {arm}.");
    }

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

    public struct PositionData
    {
        public PositionData(uint trial, double time, float x, float z, float roty)
        {
            this.trial = trial;
            this.time = time;
            this.x = x;
            this.z = z;
            this.roty = roty;
        }
        public uint trial;
        public double time;
        public float x;
        public float z;
        public float roty;

        public static implicit operator string(PositionData data)
        {
            List<string> values = new List<string>(5);
            foreach (var field in typeof(PositionData).GetFields()) {
                values.Add(field.GetValue(data).ToString());
            }
            return string.Join('\t', values);
        }
    };
};

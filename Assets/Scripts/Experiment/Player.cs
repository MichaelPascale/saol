/* Player.cs
 * Manager class for the first-person player game object.
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * SPDX-License-Identifier: MIT
 */

using UnityEngine;

public class SAOLPlayer : MonoBehaviour
{

    private CharacterController controller;

    void Start()
    {
        controller = GetComponent<CharacterController>();
    }

    void Update()
    {
        
    }

    public void teleport(Vector3 position)
    {
        bool contrl_state = controller.enabled;
        controller.enabled = false;
        transform.position = position;
        controller.enabled = contrl_state;
    }

    public void look(Vector3 direction)
    {
        bool contrl_state = controller.enabled;
        controller.enabled = false;
        transform.eulerAngles = direction;
        controller.enabled = contrl_state;
    }

    public void reset()
    {
        bool contrl_state = controller.enabled;
        controller.enabled = false;
        transform.position = new Vector3(0, 1, 0);
        transform.eulerAngles = Vector3.zero;
        controller.enabled = contrl_state;
    }

    public void pause()
    {
        controller.enabled = false;
    }

    public void unpause()
    {
        controller.enabled = true;
    }

    public Vector3 get_position()
    {
        return transform.position;
    }

    public float get_heading()
    {
        return transform.eulerAngles.y;
    }
};
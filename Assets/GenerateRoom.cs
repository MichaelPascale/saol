using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using NUnit.Framework.Internal;
using Unity.Collections;
using Unity.VisualScripting;
using UnityEditor.Rendering.Universal;
using UnityEngine;

class Room
{
    public readonly string name;
    public readonly GameObject gobj;
    public Room(string name) {
        this.name = name;
        gobj = new GameObject(name);
       
        GameObject floor = GameObject.CreatePrimitive(PrimitiveType.Plane);
        floor.name = "floor";
        floor.transform.parent = gobj.transform;


    }
}

class RoomFactory
{
    public readonly string name;
    public readonly PlacementAlgorithm alg;
    private List<Room> rooms = new List<Room>();

    public RoomFactory(string name, PlacementAlgorithm alg)
    {
        this.name = name;
        this.alg = alg;
    }
    public Room create()
    {
        Room newroom = new Room(string.Concat(name, " Room ", rooms.Count));
        rooms.Add(newroom);
        // newroom.gobj.transform.position = new Vector3(0,0,10);
        // newroom.gobj.transform.Rotate(0,72,0, Space.World);
        alg.place(newroom);
        return newroom;
    }

}

abstract class PlacementAlgorithm
{
    public abstract void place(Room room);
}

class HamletMaze : PlacementAlgorithm
{
    private int i = 0;
    private GameObject gobj;
    public HamletMaze()
    {   
        GameObject center = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        center.transform.position = new Vector3(0,2,0);
        center.transform.localScale = new Vector3(12,2,12);
    }

    public override void place(Room room)
    {
        room.gobj.transform.position = new Vector3(0,0,15);
        room.gobj.transform.RotateAround(Vector3.zero, Vector3.up, 72*i);
        i++;
    }
}
public class GenerateRoom : MonoBehaviour
{
    RoomFactory f;
    // Room test;
    // Room test2;
    void Start()
    {
        f = new RoomFactory("MyRoom", new HamletMaze());
        for (int i = 0; i < 5; i++)
            print(f.create());
        
        // test = new Room("test1");
        // test2 = new Room("test2");
        // test.gobj.transform.position = new Vector3(0,0,10);
        // test2.gobj.transform.position = new Vector3(0,0,10);
    }

    void Update()
    {
        // test.gobj.transform.RotateAround(Vector3.zero, Vector3.up, 1f);
        // test2.gobj.transform.Rotate(0,1,0, Space.Self);
    }
}

// SPDX-License-Identifier: MIT
using System;
using System.Collections.Generic;
using System.IO.Compression;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEditor.Build;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.InputSystem.Interactions;
using UnityEngine.UIElements;
using static System.Math;

public class HexTile3D
{
    public string name;
    public Vector3 location;
    public readonly GameObject gobj;
    public readonly Vector3[] hex_vertices;

    private const float HEIGHT = 1;
    private enum Directions { SouthEast, South, SouthWest, NorthWest, North, NorthEast };
    private static (int, int)[] offsets = new (int, int)[]
    {
        (1,  0), 
        (0, -1), 
        (-1,-1),
        (-1, 0),
        (0,  1),
        (1,  1) 
    };

    public HexTile3D(string name, Vector3 where, uint wflags = 0xFF, Material[] materials = null) {
        gobj = new GameObject(name);
        this.name = name;
        location = where;

        gobj.AddComponent<MeshFilter>();
        gobj.AddComponent<MeshRenderer>();
        gobj.AddComponent<MeshCollider>();

        {
            // Create a mesh for the hexagonal floor.
            Mesh mesh = new Mesh();

            // Allocate a center and six points.
            List<Vector3>
            vertices = new List<Vector3>();

            // Define the vertices of the hexagon in clockwise fashion.
            // Unity assumes the front face of a mesh has clockwise triangle winding.
            vertices.Add(Vector3.zero);
            for (uint i = 0; i < 6; i++) vertices.Add(new Vector3((float)Cos(-i*PI/3), 0, (float)Sin(-i*PI/3)));

            mesh.vertices = vertices.ToArray();
            hex_vertices = vertices.ToArray();

            // A hexagon is six triangles, six triplets of vertices.
            List<int>
            triangles = new List<int>();
            for (int i = 0; i < 6; i++) triangles.AddRange(new int[] {0, i + 1, i < 5 ? i + 2 : 1});

            mesh.triangles = triangles.ToArray();

            // Generate UVs. Will unwrap a circle through the middle of the texture.
            Vector2[] uvs = new Vector2[7];
            for (int i = 0; i < 7; i++) uvs[i] = new Vector2(vertices[i].x/2+.5f, vertices[i].z/2+.5f);
            mesh.uv = uvs;

            mesh.RecalculateNormals();
            gobj.GetComponent<MeshFilter>().mesh = mesh;
            gobj.GetComponent<MeshCollider>().sharedMesh = mesh;

            // Set the render material.
            if (materials != null && materials.Length > 0)
                gobj.GetComponent<MeshRenderer>().material = materials[0];
        }
    
        // If a ceiling is specified (seventh bit), then duplicate the floor.
        if ((wflags & 0x40) > 0)
        {
            GameObject ceil = new GameObject("ceiling");
            ceil.AddComponent<MeshFilter>();
            ceil.AddComponent<MeshRenderer>();
            ceil.AddComponent<MeshCollider>();
            Mesh mesh = new Mesh();

            List<Vector3> vertices = new List<Vector3>();
            List<int> triangles = new List<int>();

            // Counter clockwise.
            vertices.Add(new Vector3(0,HEIGHT,0));
            for (uint i = 0; i < 6; i++) vertices.Add(new Vector3((float)Cos(i * PI / 3), HEIGHT, (float)Sin(i * PI / 3)));

            mesh.vertices = vertices.ToArray();

            for (int i = 0; i < 6; i++) triangles.AddRange(new int[] { 0, i + 1, i < 5 ? i + 2 : 1 });
            mesh.triangles = triangles.ToArray();

            Vector2[] uvs = new Vector2[7];
            for (int i = 0; i < 7; i++) uvs[i] = new Vector2(vertices[i].x / 2 + .5f, vertices[i].z / 2 + .5f);
            mesh.uv = uvs;

            mesh.RecalculateNormals();
            ceil.GetComponent<MeshFilter>().mesh = mesh;
            ceil.GetComponent<MeshCollider>().sharedMesh = mesh;
            
            ceil.transform.parent = gobj.transform;
            
            if (materials != null && materials.Length > 0) {
                ceil.GetComponent<MeshRenderer>().material = materials[materials.Length - 1]; // The last material defines the ceiling.
            }
        }

        // Add a wall on the far face of each triangle, according to the walls flag.
        // Six binary flags (two octal digits) set the clockwise wall presence:
        //     southeast, south, southwest, northwest, north, northeast
        {
            GameObject walls = new GameObject("walls");
            walls.AddComponent<MeshFilter>();
            walls.AddComponent<MeshRenderer>();
            walls.AddComponent<MeshCollider>();
            Mesh mesh = new Mesh();

            List<Vector3>
            vertices = new List<Vector3>();

            List<int>
            triangles = new List<int>();

            // Starting from the least significant bit...
            int wcount = 0;
            for (int i = 0; i < 6; i++) {
                if ((wflags & 0x1u) > 0) {
                    
                    // Create Quads, starting from the bottom left corner of each.
                    vertices.AddRange(new Vector3[] {
                        new Vector3((float)Cos(-i*PI/3),     0,         (float)Sin(-i*PI/3)),
                        new Vector3((float)Cos(-i*PI/3),     HEIGHT,    (float)Sin(-i*PI/3)),
                        new Vector3((float)Cos(-(i+1)*PI/3), HEIGHT,    (float)Sin(-(i+1)*PI/3)),
                        new Vector3((float)Cos(-(i+1)*PI/3), 0,         (float)Sin(-(i+1)*PI/3)),
                    });

                    // Add triangles.
                    // Vertex indicies depend on how many walls have been created so far.
                    int o = wcount*4;
                    triangles.AddRange(new int[] {
                        o+0, o+1, o+2,
                        o+2, o+3, o+0
                    });

                    wcount++;
                }
                

                wflags = wflags >> 1;
            }

            mesh.vertices = vertices.ToArray();
            mesh.triangles = triangles.ToArray();

            Vector2[] uvs = new Vector2[vertices.Count];
            for (int i = 0; i < vertices.Count; i++) {
                int imod = i % 4;
                uvs[i] = new Vector2((imod == 1 || imod == 2) ? 1 : 0, (imod == 2|| imod == 3) ? 1 : 0);
            }
            mesh.uv = uvs;

            mesh.RecalculateNormals();
            walls.GetComponent<MeshFilter>().mesh = mesh;
            walls.GetComponent<MeshCollider>().sharedMesh = mesh;

            walls.transform.parent = gobj.transform;
            
            if (materials != null && materials.Length > 0) {
                walls.GetComponent<MeshRenderer>().material = materials[materials.Length > 1 ? 1 : 0];
            }
        }

        gobj.transform.position = where;
    }

    // Convert axial coordinates to a cartesian grid. Use for hex placement.
    //      The axial x-axis is parallel to the cartesian x-axis.
    //      The axial d-axis is diagonal at -30deg to the cartesian x-axis.
    public static Vector3 ax2cart(int xax, int dax, float y = 0)
    {
        return new Vector3(1.5f * xax, y, (float) (-Sqrt(3)/2*xax + Sqrt(3)*dax));

    }
    public static (int, int) adjax(int xax, int dax, uint dir)
    {
        (int x, int d) = offsets[dir];
        return (xax + x, dax + d);
    }

    // Given a numbered face (0-5), return the center vector.
    public Vector3 getFaceCenter(uint face) { 
        // Skip 0, the center vertex
        return ((hex_vertices[face+1] + hex_vertices[face == 5 ? 1 : face+2]) /2)+ Vector3.up * HEIGHT / 2;   
    }
}



public class HexTiles : MonoBehaviour
{

    public Material mat_walls;
    public Material mat_floor;

    public Material mat_ceil;

    public List<Texture> object_textures;
    void Start()
    {
        Material[] materials = {mat_floor, mat_walls, mat_ceil};
        // HexTile3D h = new HexTile3D("test hex", Vector3.zero, 0x37, materials);
        // new HexTile3D("northeast", new Vector3(1.5f, 0, (float)Sqrt(3)/2), 0x3A, materials);
        // new HexTile3D("east", new Vector3(3, 0, 0), 0x1F, materials);

        new HexTile3D("sw", HexTile3D.ax2cart(0,0), 0x40 + 0x0e, materials);
        new HexTile3D("nw", HexTile3D.ax2cart(0,1), 0x40 + 0x3c, materials);
        new HexTile3D("ne", HexTile3D.ax2cart(1,1), 0x40 + 0x31, materials);
        Vector3 cent = se.getFaceCenter(3);
        cent.x = cent.x * .9f;
        cent.z = cent.z * .9f;
        GameObject painting = GameObject.CreatePrimitive(PrimitiveType.Plane); //new GameObject("painting"); 
        painting.name = "painting";

        painting.transform.parent = se.gobj.transform;
        painting.transform.localPosition = cent;
        painting.transform.localScale = Vector3.one * .05f;
        painting.transform.LookAt(Vector3.up / 2); // TODO: * HEIGHT which is inside the hextile class
        painting.transform.Rotate(90, 0, 0);
        painting.GetComponent<Renderer>().material.mainTexture = ImportTexture.loadTexture("Assets/Textures/SVLO/001.png");


        for (int x = 0; x < 20; x++) {
            for (int z = 10; z < 30; z++) {
                uint wall_config = 0x00;
                if (x == 0)  wall_config |= 0x0c;
                if (x == 19) wall_config |= 0x21;
                if (z == 10) wall_config |= 0x06;
                if (z == 29) wall_config |= 0x30;
                HexTile3D hex = new HexTile3D(String.Concat("(", x, ", ", z, ")"), HexTile3D.ax2cart(x,z,1), 0x40 + wall_config, materials);

                if (x == 0) {
                    Vector3 ce = hex.getFaceCenter((uint) (2 + z%2));
                    ce.x = ce.x * .9f;
                    ce.z = ce.z * .9f;

                    GameObject pt = GameObject.CreatePrimitive(PrimitiveType.Plane); //new GameObject("painting"); 
                    pt.name = "painting";


                    pt.transform.parent = hex.gobj.transform;
                    pt.transform.localPosition = ce;
                    pt.transform.localScale = Vector3.one * .05f;
                    pt.transform.LookAt(hex.gobj.transform.position + Vector3.up / 2); // TODO: * HEIGHT which is inside the hextile class
                    pt.transform.Rotate(90, 0, 0, Space.Self);
                    
                    pt.GetComponent<Renderer>().material.mainTexture = object_textures[z%6];
                }
            }
        }

    }

    void Update()
    {

    }
}
using static System.MathF;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.ProBuilder;
using UnityEngine.ProBuilder.MeshOperations;

public class generate_radialmaze_8arm : MonoBehaviour
{

    List<Face>
    find_faces(ProBuilderMesh mesh, IEnumerable<Face> faces, Vector3 direction, float thresh = .99f)
    {
        List<Face> match = new();
        foreach (Face face in faces)
        {
            Vector3 norm = Math.Normal(mesh, face);
            if (norm == direction)//Vector3.Dot(norm, direction) > thresh)
                match.Add(face);

        }
        return match;
    } 
    void Start()
    {
        int narms = 8;
        int nsides = 2*(narms + 1);
        float hall_length = 2;

        /* Radial Maze Center ************************************************/
        ProBuilderMesh cyl = ShapeGenerator.GenerateCylinder(PivotLocation.Center, nsides, .5f, 1, 5, -1);

        // Delete the faces which will align with hallways.
        for (int j = 1; j <= 8; j++)
            cyl.DeleteFaces(find_faces(cyl, cyl.faces, new Vector3(Sin(4 * j * PI / nsides), 0, Cos(4 * j * PI / nsides))));

        // Cleanup, invert normals, apply the material, etc.
        for (int i = 0; i < cyl.faceCount; i++) cyl.faces[i].Reverse();
        cyl.ToMesh();
        cyl.Refresh();
        cyl.GetComponent<Renderer>().material = BuiltinMaterials.defaultMaterial;

        /* Radial Maze Arms **************************************************/
        for (int j = 1; j <= narms; j++)
        {
            ProBuilderMesh arm = ShapeGenerator.GenerateCube(
                PivotLocation.Center,
                new Vector3(Sin(PI / nsides), 1, hall_length)
            );
            arm.name = "arm" + j;

            // Delete the -Z face, which will align with the maze center.
            arm.DeleteFaces(find_faces(arm, arm.faces, Vector3.back));
            arm.DeleteFaces(find_faces(arm, arm.faces, Vector3.forward));

            // Hallway end
            ProBuilderMesh end = ShapeGenerator.GenerateCube(
                PivotLocation.Center,
                new Vector3(Sin(PI / nsides), 1, hall_length/4)
            );

            end.transform.position = new Vector3(0, 0, 5*hall_length/8);
            end.DeleteFaces(find_faces(end, end.faces, Vector3.back));
            end.DeleteFaces(find_faces(end, end.faces, Vector3.right));

            // Alcove
            ProBuilderMesh alc = ShapeGenerator.GenerateCube(
                PivotLocation.Center,
                new Vector3(Sin(PI / nsides), 1, hall_length/4)
            );

            alc.transform.position = new Vector3(Sin(PI/nsides), 0, 5*hall_length/8);
            alc.DeleteFaces(find_faces(alc, alc.faces, Vector3.left));

            // Combine the arm, end, and alcove into one mesh.
            List<ProBuilderMesh> ms = CombineMeshes.Combine(new[] { arm, end, alc }, arm);
            Debug.Log(ms.Count);
            Destroy(end.gameObject);
            Destroy(alc.gameObject);
            arm = ms[0];

            // TODO: Weld vertices.
            // FIXME: Invert normals all at once.
            

            // Rotate and move the arm so that it is aligned with the maze center door.
            arm.SetPivot(new Vector3(0, 0, -hall_length / 2));
            arm.transform.Rotate(Vector3.up, 2 * j * 360 / nsides);
            float x = (Sin(PI / nsides * (4 * j - 1)) + Sin(PI / nsides * (4 * j + 1))) / 4;
            float z = (Cos(PI / nsides * (4 * j - 1)) + Cos(PI / nsides * (4 * j + 1))) / 4;
            arm.transform.position = new Vector3(x, .5f, z);

            // Cleanup, invert normals, apply the material, etc.
            for (int i = 0; i < arm.faceCount; i++) arm.faces[i].Reverse();
            arm.ToMesh();
            arm.Refresh();
            arm.GetComponent<Renderer>().material = BuiltinMaterials.defaultMaterial;
        }

    }

    void Update()
    {

    }
}

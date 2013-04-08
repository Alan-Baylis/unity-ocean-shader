using UnityEngine;
using System.Collections;

public class SimpleMesh : MonoBehaviour {

    public Vector3[] verts;
    public Vector3[] uvs;
    public int[] tris;

    //resolution in verts
    public int resolution;
    public float scale;

    private MeshFilter meshFilter;

	void Start () {
        //initialize the array for storing verts
        verts = new Vector3[resolution * resolution];
        tris = new int[(resolution - 1) * (resolution - 1) * 2 * 3];

        Mesh mesh = new Mesh();
        //Optimize for frequent updates
        meshFilter = GetComponent<MeshFilter>();
        meshFilter.mesh = mesh;
        

        //Create vertices and triangles
        int lastTri = 0; //last triangle index
        for (int i = 0; i < resolution; i++)
        {
            for (int j = 0; j < resolution; j++) 
            {
                verts[(i * resolution) + j] = new Vector3(i * scale, 0, j * scale);
                if (i + 1 < resolution && j + 1 < resolution)
                {
                    //Triangle 1 of sqaure
                    tris[lastTri] = (i * resolution) + j;
                    tris[lastTri + 1] = ((i + 1) * resolution) + j;
                    tris[lastTri + 2] = (i * resolution) + j + 1;
                    //Triangle 2 of sqaure
                    tris[lastTri + 3] = (i * resolution) + j + 1;
                    tris[lastTri + 4] = ((i + 1) * resolution) + j;
                    tris[lastTri + 5] = ((i + 1) * resolution) + j + 1;
           
                    lastTri += 6;
                }

            }
        }

        mesh.MarkDynamic();
        mesh.vertices = verts;
        mesh.triangles = tris;
        
	}

    void Update()
    {
        meshFilter.mesh.vertices = verts;
        meshFilter.mesh.RecalculateNormals();
        //Reset verts
        for (int i = 0; i < verts.Length; i++)
        {
            verts[i].y = 0.0f;
        }
        /*
        for (int i = 0; i < verts.Length; i++)
        {
            Debug.DrawRay(verts[i], meshFilter.mesh.normals[i] * 0.25f);
        }
        */
        //meshFilter.mesh.triangles = tris;
	}
}

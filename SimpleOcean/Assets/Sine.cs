using UnityEngine;
using System.Collections;

public class Sine : MonoBehaviour {

    public float scale;
    public float amplitude;
    public float speed;
    //Used for scrolling the sine wave
    private float offset = 0.0f;

    private SimpleMesh simpleMesh;
	// Use this for initialization
	void Start () {
        simpleMesh = gameObject.GetComponent<SimpleMesh>();
	}
	
	// Update is called once per frame
	void Update () {
        for (int i = 0; i < simpleMesh.verts.Length; i++)
        {
            simpleMesh.verts[i].y += Mathf.Sin(simpleMesh.verts[i].x * scale + offset * speed) * 0.0f;
            simpleMesh.verts[i].y += Mathf.Sin(simpleMesh.verts[i].z * scale + offset * speed) * amplitude;
        }
        offset += Time.deltaTime;
        if (offset > 2 * Mathf.PI)
        {
            offset = 0.0f;
        }
	}
}

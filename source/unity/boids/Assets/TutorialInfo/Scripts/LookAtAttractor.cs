using UnityEngine;
using System.Collections;
using System.Collections.Generic;
public class LookAtAttractor : MonoBehaviour
{
    // Start is called once before the first execution of Update after the MonoBehaviour is created

    void Update()
    {
        transform.LookAt(Attractor.POS);
    }
}

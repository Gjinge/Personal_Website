using UnityEngine;
using System.Collections;
using System.Collections.Generic;
public class AppleTree : MonoBehaviour
{
    [Header("Set in Inspector")]

    public GameObject applePrefab;

    public float speed = 1f;

    public float LeftAndRightEdge = 10f;

    public float chanceToChangeDirections = 0.02f;

    public float secondsBetweenAppleDrops = 1f;



    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        Invoke("DropApple", 2f);
    }

    void DropApple()
    {
        GameObject apple = Instantiate<GameObject>(applePrefab);
        apple.transform.position = transform.position;
        Invoke("DropApple", secondsBetweenAppleDrops);
        
}
    // Update is called once per frame
    void Update()
    {
        Vector3 pos = transform.position;
        pos.x += speed * Time.deltaTime;
        transform.position = pos;

        if (pos.x < -LeftAndRightEdge)
        {
            speed = Mathf.Abs(speed);
        }
        else if (pos.x > LeftAndRightEdge)
        {
            speed = -Mathf.Abs(speed);
        }

    }
        void FixedUpdate()
        {
            if (Random.value < chanceToChangeDirections)
            {
                speed *= -1;
            }
        }
    
}

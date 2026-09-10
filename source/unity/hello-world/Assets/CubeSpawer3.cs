using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class CubeSpawner3 : MonoBehaviour {
    public GameObject cubePrefabVar;
    public List<GameObject> gameObjectList;      // 用于存储所有的立方体
    public float scalingFactor = 0.95f;          // 每个立方体每帧缩小的比例
    public int numCubes = 0;                     // 已初始化的立方体数目

    // Start() 用于初始化
    void Start() {
        // 本句用于初始化 List<GameObject>
        gameObjectList = new List<GameObject>();
    }

    // 每帧都会调用一次 Update()
    void Update() {
        numCubes++;                              // 使立方体数目增加1
        GameObject gObj = Instantiate(cubePrefabVar) as GameObject;   // 实例化一个新的立方体
    
            gObj.name = "Cube " + numCubes;  // c
        Color c = new Color(Random.value, Random.value, Random.value);  // d
        gObj.GetComponent<Renderer>().material.color = c;  
        gObj.transform.position = Random.insideUnitSphere;  
        gameObjectList.Add(gObj);  

        List<GameObject> removeList = new List<GameObject>();  

        foreach (GameObject goTemp in gameObjectList) {  

            float scale = goTemp.transform.localScale.x; 
            scale *= scalingFactor;  
            goTemp.transform.localScale = Vector3.one * scale;

            if (scale <= 0.1f) {  // 如果尺寸小于 0.1f.....
                removeList.Add(goTemp);  // 则加到 removeList 中
            }
        }

        foreach (GameObject goTemp in removeList) {
            gameObjectList.Remove(goTemp);  // 从 gameObjectList 中删除这个立方体
            Destroy(goTemp); // 销毁立方体 GameObject
        }
    }
}

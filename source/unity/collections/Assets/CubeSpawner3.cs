using System.Collections.Generic;
using UnityEngine;
using System.Collections;

public class CubeManager : MonoBehaviour
{
    public int numCubes = 10; // 要生成的立方体数量
    public float scalingFactor = 0.95f; // 每帧缩放比例

    private List<GameObject> gameObjectList = new List<GameObject>();

    void Start()
    {
        for (int i = 0; i < numCubes; i++)
        {
            GameObject gObj = GameObject.CreatePrimitive(PrimitiveType.Cube);
            gObj.name = "Cube " + i; // c: 设置每个立方体的名字
            Color c = new Color(Random.value, Random.value, Random.value); // d: 随机颜色
            gObj.GetComponent<Renderer>().material.color = c;
            gObj.transform.position = Random.insideUnitSphere; // e: 随机位置
            gameObjectList.Add(gObj); // f: 将立方体添加到列表中
        }
    }

    void Update()
    {
        List<GameObject> removeList = new List<GameObject>(); // 创建一个列表用于存储需要移除的立方体

        foreach (GameObject goTemp in gameObjectList)
        {
            float scale = goTemp.transform.localScale.x; // h: 获取当前立方体的大小
            scale *= scalingFactor; // 缩小立方体
            goTemp.transform.localScale = Vector3.one * scale;

            if (scale <= 0.1f) // 如果尺寸小于0.1f...
            {
                removeList.Add(goTemp); // 则加到removeList中
            }
        }

        foreach (GameObject goTemp in removeList)
        {
            gameObjectList.Remove(goTemp); // j: 从列表中移除立方体
            Destroy(goTemp); // 销毁立方体 GameObject
        }
    }
}
using System.Collections.Generic;
using UnityEngine;

public class DifficultyManager : MonoBehaviour
{
    public List<float> appleDropSpeeds = new List<float> { 1f, 0.5f, 0.25f, 0.125f, 0.1f };
    public List<float> treeMoveSpeeds = new List<float> { 20f, 25f, 30f, 35f, 40f };
    private int level = 0;
    private AppleTree appleTree;

    void Start()
    {
        appleTree = FindObjectOfType<AppleTree>();
        InvokeRepeating(nameof(IncreaseDifficulty), 10f, 5f);  
    }

    void IncreaseDifficulty()
    {
        if (appleTree == null) return;

        if (level < appleDropSpeeds.Count - 1)
        {
            level++;
            appleTree.speed = treeMoveSpeeds[level];
            appleTree.secondsBetweenAppleDrops = appleDropSpeeds[level];
        }
        else
        {
            appleTree.speed += 0.5f;  
            appleTree.secondsBetweenAppleDrops = Mathf.Max(0.05f, appleTree.secondsBetweenAppleDrops - 0.05f); 
        }
    }
}

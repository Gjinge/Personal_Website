using UnityEngine;

public class ScoreManager : MonoBehaviour
{
    public static int currentScore = 0; // 本局游戏得分

    public static void AddScore(int points)
    {
        currentScore += points;
    }

    public static void ResetScore()
    {
        currentScore = 0;
    }
}

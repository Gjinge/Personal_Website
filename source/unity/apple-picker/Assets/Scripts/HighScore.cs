using UnityEngine;
using TMPro;

public class HighScore : MonoBehaviour
{
    static public int score = 0;  // 当前得分
    private TextMeshProUGUI scoreText;

    void Awake()
    {
        scoreText = GetComponent<TextMeshProUGUI>();

        // 检查是否存在已保存的高分
        if (PlayerPrefs.HasKey("HighScore"))
        {
            score = PlayerPrefs.GetInt("HighScore");
        }

        PlayerPrefs.Save();  // 确保保存
    }

    void Update()
    {
        if (scoreText != null)
        {
            // 更新UI显示高分
            scoreText.text = "High Score: " + score;
        }

        // 如果当前得分比保存的高分高，则更新高分
        int savedHighScore = PlayerPrefs.GetInt("HighScore", 0);
        if (score > savedHighScore)
        {
            PlayerPrefs.SetInt("HighScore", score);
            PlayerPrefs.Save();
        }
    }

    // 清空高分
    public void ClearHighScore()
    {
        PlayerPrefs.DeleteKey("HighScore");  // 删除 HighScore
        score = 0;  // 重置当前的 score
        PlayerPrefs.Save();  // 保存更改
    }
}

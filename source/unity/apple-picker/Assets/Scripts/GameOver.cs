using UnityEngine;
using UnityEngine.SceneManagement;
using TMPro;

public class GameOver : MonoBehaviour
{
    public TextMeshProUGUI finalScoreText;
    public TextMeshProUGUI highScoreText;
    public TextMeshProUGUI newRecordText;

    void Start()
    {
        int finalScore = PlayerPrefs.GetInt("FinalScore", 0);
        finalScoreText.text = ": " + finalScore;

        int highScore = PlayerPrefs.GetInt("HighScore", 0);

        if (finalScore == highScore)
        {
            PlayerPrefs.SetInt("HighScore", finalScore);
            PlayerPrefs.Save();
            highScoreText.text = "新记录！最高分: " + finalScore;
            newRecordText.text = "恭喜！你打破了记录！";
        }
        else
        {
            highScoreText.text = "最高分: " + highScore;
            newRecordText.text = "";
        }
    }

    public void RestartGame()
    {
        SceneManager.LoadScene("_Scene_0");
    }

    public void BackToMenu()
    {
        SceneManager.LoadScene("_StartScene");
    }

    public void ClearHighScore()
    {
        PlayerPrefs.DeleteKey("HighScore");
        highScoreText.text = "最高分: 0";
        newRecordText.text = "";
    }
}

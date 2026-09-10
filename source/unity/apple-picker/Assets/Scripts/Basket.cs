using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine.SceneManagement;

public class Basket : MonoBehaviour
{
    [Header("Set Dynamically")]
    public TextMeshProUGUI scoreGT;
    static public int points = 100;
    private AudioSource audioSource; // 添加音源变量
    public AudioClip appleCatchSound; // 公开音效变量，方便在 Unity 里拖拽音效
    public static int currentscore = 0;
    void Start()
    {
        GameObject scoreGO = GameObject.Find("ScoreCounter");
        scoreGT = scoreGO.GetComponent<TextMeshProUGUI>();
        scoreGT.text = "0";

        // 获取或添加 AudioSource 组件
        audioSource = GetComponent<AudioSource>();
        if (audioSource == null)
        {
            audioSource = gameObject.AddComponent<AudioSource>();
        }
    }

    void Update()
    {
        Vector3 mousePos2D = Input.mousePosition;
        mousePos2D.z = -Camera.main.transform.position.z;

        Vector3 mousePos3D = Camera.main.ScreenToWorldPoint(mousePos2D);

        Vector3 pos = this.transform.position;
        pos.x = mousePos3D.x;
        this.transform.position = pos;
    }

    void OnCollisionEnter(Collision coll)
    {
        GameObject collidedWith = coll.gameObject;
        if (collidedWith.tag == "Apple")
        {
            Destroy(collidedWith);

            // 播放音效
            if (appleCatchSound != null)
            {
                audioSource.PlayOneShot(appleCatchSound);
            }

            int score = int.Parse(scoreGT.text);
            score += points;
            scoreGT.text = score.ToString();

            currentscore = score;

            if (score > HighScore.score)
            {
                HighScore.score = score;
            }



        }
    }
}

using UnityEngine;

public class NewMonoBehaviourScript : MonoBehaviour
{
    public static float bottomY = -20f;
    public AudioClip fallSound;
    private bool hasPlayedSound = false;


    void Update()
    {
        if (transform.position.y < bottomY)
        {
            Destroy(this.gameObject);

            ApplePicker apScript = Camera.main.GetComponent<ApplePicker>();

            apScript.AppleDestroyed();
        }

        if (transform.position.y < bottomY && !hasPlayedSound)
        {
            hasPlayedSound = true;
            AudioSource.PlayClipAtPoint(fallSound, Camera.main.transform.position);
            Destroy(gameObject);
        }
    }
}

using UnityEngine;
using System.Collections;

public class Slingshot : MonoBehaviour
{
    [Header("Set in Inspector")]
    public GameObject prefabProjectile;
    public float velocityMult = 8f;

    static public Slingshot S;
        static public Vector3 LAUNCH_POS
        {
            get
            {
                if (S == null) return Vector3.zero;
                return S.lauchPos;
            }
        }
      


    [Header("Set Dynamically")]
    public GameObject lauchPoint;
    public Vector3 lauchPos;
    public GameObject projectile;
    public bool aimingMode;

    void Awake()
    {
    S = this;
    Transform launchPointTrans = transform.Find("LaunchPoint");
        lauchPoint = launchPointTrans.gameObject;
        lauchPoint.SetActive(false);
        lauchPos = launchPointTrans.position;
    }
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void OnMouseEnter()
    {
        // print("Slingshot:OnMouseEnter()");
        lauchPoint.SetActive(true);
    }

    void OnMouseExit()
    {
        // print("Slingshot:OnMouseExit()");
        lauchPoint.SetActive(false);
    }

    void OnMouseDown()
    {
        aimingMode = true;
        projectile = Instantiate(prefabProjectile) as GameObject;
        projectile.transform.position = lauchPos;
        projectile.GetComponent<Rigidbody>().isKinematic = true;
    }

    void Update()
    {
        if (!aimingMode) return;
        Vector3 mousePos2D = Input.mousePosition;
        mousePos2D.z = -Camera.main.transform.position.z;
        Vector3 mousePos3D = Camera.main.ScreenToWorldPoint(mousePos2D);
        Vector3 mouseDelta = mousePos3D - lauchPos;
        float maxMagnitude = this.GetComponent<SphereCollider>().radius;
        if (mouseDelta.magnitude > maxMagnitude)
        {
            mouseDelta.Normalize();
            mouseDelta *= maxMagnitude;
        }
        Vector3 projPos = lauchPos + mouseDelta;
        projectile.transform.position = projPos;
        if (Input.GetMouseButtonUp(0))
        {
            aimingMode = false;
            projectile.GetComponent<Rigidbody>().isKinematic = false;
            projectile.GetComponent<Rigidbody>().linearVelocity = -mouseDelta * velocityMult;

            FollowCam.POI = projectile;
            projectile = null;

            MissionDemolition.ShotFired();
            ProjectileLine.S.poi = projectile;
        }
    }
}

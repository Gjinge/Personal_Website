using UnityEngine; // a
using System.Collections; // b
using System.Collections.Generic; // c

public class ListEx : MonoBehaviour {
    public List<string> sList; // d

    void Start() {
        sList = new List<string>(); // e
        sList.Add("Experience"); // f
        sList.Add("is");
        sList.Add("what");
        sList.Add("you");
        sList.Add("get");
        sList.Add("when");
        sList.Add("you");
        sList.Add("didn't");
        sList.Add("get");
        sList.Add("what");
        sList.Add("you");
        sList.Add("wanted.");

        //上面的话出自我的导师Randy Pausch博士 (1960-2008)

        print("sList Count =" + sList.Count); // g
        print("第0个元素为:" + sList[0]); // h
        print("第1个元素为：" + sList[1]);
        print("第3个元素为：" + sList[3]);
        print("第8个元素为：" + sList[8]);

        string str = "";
        foreach (string sTemp in sList) { // i
            str += sTemp + " ";
        }
        print(str);
    }
}

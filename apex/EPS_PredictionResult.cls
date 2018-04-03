/*
 * Einstein Platform Services の返り値を Apex で扱いやすくするためのクラス
 * 返り値の JSON をこのクラスにパースして使う
 * 参考: https://json2apex.herokuapp.com/
 * 作成: Hiroyuki Inaba | Salesforce | 20180405
 */
public class EPS_PredictionResult {

    public List<Probabilities> probabilities;
    
    public class Probabilities {
        public String label;
        public Double probability;
    }
    
    public static EPS_PredictionResult parse(String json) {
        return (EPS_PredictionResult) System.JSON.deserialize(json, EPS_PredictionResult.class);
    }
}
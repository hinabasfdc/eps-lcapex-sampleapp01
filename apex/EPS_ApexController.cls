/*
* Einstein Platform Services への API アクセスを行う定義・関数群
* 注意: Webセミナー用に無理に1つのクラスに詰め込んだもの。エラー検知処理なども最低限なので、実際のアプリ開発にあたっては適切な設計を推奨
* 作成: Hiroyuki Inaba | Salesforce | 20180405
*/
public class EPS_ApexController {
    
    /*
* URL関連定数の定義
*/
    private static String BASE_URL = 'https://api.einstein.ai/v2';
    private static String OAUTH2_URL = BASE_URL + '/oauth2/token';    
    private static String IMAGECLASSIFICATION_URL = BASE_URL + '/vision/predict';
    private static String OBJECTDETECTION_URL = BASE_URL + '/vision/detect';
    private static String SENTIMENT_URL = BASE_URL + '/language/sentiment';
    private static String INTENT_URL = BASE_URL + '/language/intent';
    
    /*
* Vision のAPIを呼び出す関数
*/
    @AuraEnabled
    public static String getVisionPrediction(String predictiontype, String modelId, String base64img, String eps_account, String eps_key) {
        
        //実行する機能種別に応じてURLを切り替え
        String URL = IMAGECLASSIFICATION_URL;
        if (predictiontype == 'OBJECTDETECTION') { URL = OBJECTDETECTION_URL; }
        
        //multipart/form-dataで送る必要があるのでformデータを組立        
        String form64 = '';
        form64 += WriteBoundary();
        form64 += WriteBodyParameter('modelId', EncodingUtil.urlEncode(modelId, 'UTF-8'));
        form64 += WriteBoundary();
        form64 += WriteBodyParameter('sampleBase64Content', base64img);
        form64 += WriteBoundary(EndingType.CrLf);
        blob formBlob = EncodingUtil.base64Decode(form64);
        
        //Httpリクエスト文を組立
        HttpRequest req = new HttpRequest();
        req.setBodyAsBlob(formBlob);
        req.setHeader('Connection', 'keep-alive');
        req.setHeader('Content-Length', string.valueOf(formBlob.size()));
        req.setHeader('Content-Type', GetContentType());
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setHeader('Authorization','Bearer ' + getAccessToken(eps_account, eps_key));
        req.setEndpoint(URL);
        
        Http http = new Http();
        String retval = '';
        try {
            //Einstein Platform Serives の API 呼出実行し結果を格納
            HTTPResponse res = http.send(req);
            retval = res.getBody();
            
            //呼出の結果ステータスが200の場合は結果をオブジェクトに保存
            if (res.getStatusCode() == 200) {
                //JSON形式の返り値を扱いやすいようにクラスにパース
                EPS_PredictionResult predictionresult = EPS_PredictionResult.parse(retval);                
                //結果が0件でなければオブジェクトにレコードを保存する関数を呼出
                /*
                if(!predictionresult.probabilities.isEmpty()){
                    createRecord(predictiontype, modelId, 'Vision', retval, base64img, predictionresult.probabilities[0].label);
                }
                */
            }
        } catch(System.CalloutException e) {
            //Exceptionをキャッチした場合はログに出力し、結果格納用変数にエラーメッセージを格納
            System.debug('ERROR:' + e);
            retval = e.getMessage();
        }
        
        //結果を返す
        return retval;
    }
    
    /*
* Language のAPIを呼び出す関数
*/
    @AuraEnabled
    public static String getLanguagePrediction(String predictiontype, String modelId, String text, String eps_account, String eps_key) {
        
        //実行する機能種別に応じてURLを切り替え
        String URL = SENTIMENT_URL;
        if (predictiontype == 'INTENT') { URL = INTENT_URL; }
        
        //json形式で送る本文を組立        
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('modelId', modelId);
        gen.writeStringField('document', text);
        gen.writeEndObject();
        
        //Httpリクエスト文を組立        
        HttpRequest req = new HttpRequest();
        req.setBody(gen.getAsString());
        req.setHeader('Connection', 'keep-alive');
        req.setHeader('Content-Length', String.valueOf(gen.getAsString().length()));
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setHeader('Authorization','Bearer ' + getAccessToken(eps_account, eps_key));
        req.setEndpoint(URL);
        
        Http http = new Http();
        String retval = '';
        try {
            //Einstein Platform Serives の API 呼出実行し結果を格納
            HTTPResponse res = http.send(req);
            retval = res.getBody();
            
            //呼出の結果ステータスが200の場合は結果をオブジェクトに保存
            if (res.getStatusCode() == 200) {
                
                //JSON形式の返り値を扱いやすいようにクラスにパース
                EPS_PredictionResult predictionresult = EPS_PredictionResult.parse(retval);
                //オブジェクトにレコードを保存する関数を呼出
                //結果が0件でなければオブジェクトにレコードを保存する関数を呼出
                /*
                if(!predictionresult.probabilities.isEmpty()){
                    createRecord(predictiontype, modelId, text, retval, '', predictionresult.probabilities[0].label);
                }
                */
            }
        } catch(System.CalloutException e) {
            //Exceptionをキャッチした場合はログに出力し、結果格納用変数にエラーメッセージを格納
            System.debug('ERROR:' + e);
            retval = e.getMessage();
        }
        
        //結果を返す
        return retval;
    }
    
    /*
* オブジェクトに結果を格納する関数
*/
/*
    private static void createRecord(String predictiontype, String modelId, String originaltext, String results, String base64img, String firstlabel) {
        
        //オブジェクトの型を取得し値を格納
        PredictionResult__c pr = new PredictionResult__c();
        pr.PredictionType__c = predictiontype;
        pr.ModelId__c = modelId;
        pr.OriginalText__c = originaltext;
        pr.PredictionResultRawText__c = results;
        pr.FirstLabel__c = firstlabel;
        //オブジェクトにレコードを追加(追加後にIdは格納される)
        insert pr;
        
        //もし機能種別がVision系だったならば、画像を"ファイル"に保存し、レコードに関連づける        
        if(predictiontype == 'IMAGECLASSIFICATION' || predictiontype == 'OBJECTDETECTION'){
            
            //"ファイル"の実体の型を取得
            ContentVersion cv = new ContentVersion();
            //ファイル名を予測結果オブジェクトのレコード名(自動採番)とするので、Idで検索し必要なデータを格納
            pr = [SELECT Id, Name FROM PredictionResult__c WHERE Id =: pr.Id];
            cv.Title = pr.Name;
            cv.PathOnClient = pr.Name + '.jpg';
            cv.VersionData = EncodingUtil.base64Decode(base64img);
            //"ファイル"に追加
            insert cv;
            
            //"予測結果"と追加したファイルを関連づけるレコードの型を取得            
            ContentDocumentLink cdl = new ContentDocumentLink();
            //ContentVersionのDocumentIdが必要なので、Idで検索し必要なデータを格納
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id];
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = pr.Id;
            cdl.ShareType = 'V';
            //関連付けを追加            
            insert cdl;
        }
    }
*/
    
    /* ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 
* 以下は共通機能セクション
* ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- */
    
    private static String getAccessToken(String eps_account, String eps_key) {
        eps_key = eps_key.replace('-----BEGIN RSA PRIVATE KEY-----', '');
        eps_key = eps_key.replace('-----END RSA PRIVATE KEY-----', '');
        eps_key = eps_key.replace('\n', '');
        
        // Get a new token
        EinsteinAI_JWT jwt = new EinsteinAI_JWT('RS256');
        jwt.pkcs8 = eps_key;
        jwt.iss = 'developer.force.com';
        jwt.sub = eps_account;
        jwt.aud = OAUTH2_URL;
        jwt.exp = '60';
        
        String access_token = '';       
        if (!Test.isRunningTest()) {
            String body = 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + jwt.issue(); 
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(OAUTH2_URL);
            req.setHeader('Content-type', 'application/x-www-form-urlencoded');
            req.setBody(body);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            if ( res.getStatusCode() == 200 ) {
                System.JSONParser parser = System.JSON.createParser(res.getBody());
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                        parser.nextToken();
                        access_token = parser.getText();
                        break;
                    }
                }
            }
        }
        
        return access_token;    
    }
    
    private class EinsteinAI_JWT {
        
        public String alg {get;set;}
        public String iss {get;set;}
        public String sub {get;set;}
        public String aud {get;set;}
        public String exp {get;set;}
        public String iat {get;set;}
        public Map<String,String> claims {get;set;}
        public Integer validFor {get;set;}
        public String cert {get;set;}
        public String pkcs8 {get;set;}
        public String privateKey {get;set;}
        
        public String HS256 = 'HS256';
        public String RS256 = 'RS256';
        public String NONE = 'none';
        
        public EinsteinAI_JWT(String alg) {
            this.alg = alg;
            this.validFor = 300;
        }
        
        public String issue() {
            String jwt = '';
            JSONGenerator header = JSON.createGenerator(false);
            header.writeStartObject();
            header.writeStringField('alg', this.alg);
            header.writeEndObject();
            String encodedHeader = base64URLencode(Blob.valueOf(header.getAsString()));
            JSONGenerator body = JSON.createGenerator(false);
            body.writeStartObject();
            body.writeStringField('iss', this.iss);
            body.writeStringField('sub', this.sub);
            body.writeStringField('aud', this.aud);
            Long rightNow = (dateTime.now().getTime()/1000)+1;
            body.writeNumberField('iat', rightNow);
            body.writeNumberField('exp', (rightNow + validFor));
            if (claims != null) {
                for (String claim : claims.keySet()) {
                    body.writeStringField(claim, claims.get(claim));
                }
            }
            body.writeEndObject();jwt = encodedHeader + '.' + base64URLencode(Blob.valueOf(body.getAsString()));
            if ( this.alg == HS256 ) {
                Blob key = EncodingUtil.base64Decode(privateKey);
                Blob signature = Crypto.generateMac('hmacSHA256',Blob.valueof(jwt),key);
                jwt += '.' + base64URLencode(signature);
            } else if ( this.alg == RS256 ) {
                Blob signature = null;
                if (cert != null ) {
                    signature = Crypto.signWithCertificate('rsa-sha256', Blob.valueOf(jwt), cert);
                } else {
                    Blob privateKey = EncodingUtil.base64Decode(pkcs8);
                    signature = Crypto.sign('rsa-sha256', Blob.valueOf(jwt), privateKey);
                }
                jwt += '.' + base64URLencode(signature);
            } else if ( this.alg == NONE ) {
                jwt += '.';
            }
            return jwt;        
        }
        
        public String base64URLencode(Blob input){ 
            String output = encodingUtil.base64Encode(input);
            output = output.replace('+', '-');
            output = output.replace('/', '_');
            while ( output.endsWith('=')){
                output = output.subString(0,output.length()-1);
            }
            return output;
        }
    }
    
    //  The boundary is alligned so it doesn't produce padding characters when base64 encoded.
    private final static string Boundary = '1ff13444ed8140c7a32fc4e6451aa76d';
    
    /**
*  Returns the request's content type for multipart/form-data requests.
*/
    private static string GetContentType() {
        return 'multipart/form-data; charset="UTF-8"; boundary="' + Boundary + '"';
    }
    
    /**
*  Pad the value with spaces until the base64 encoding is no longer padded.
*/
    private static string SafelyPad(
        string value,
        string valueCrLf64,
        string lineBreaks) {
            string valueCrLf = '';
            blob valueCrLfBlob = null;
            
            while (valueCrLf64.endsWith('=')) {
                value += ' ';
                valueCrLf = value + lineBreaks;
                valueCrLfBlob = blob.valueOf(valueCrLf);
                valueCrLf64 = EncodingUtil.base64Encode(valueCrLfBlob);
            }
            
            return valueCrLf64;
        }
    
    /**
*  Write a boundary between parameters to the form's body.
*/
    private static string WriteBoundary() {
        string value = '--' + Boundary + '\r\n';
        blob valueBlob = blob.valueOf(value);
        
        return EncodingUtil.base64Encode(valueBlob);
    }
    
    /**
*  Write a boundary at the end of the form's body.
*/
    private static string WriteBoundary(
        EndingType ending) {
            string value = '';
            
            if (ending == EndingType.Cr) {
                //  The file's base64 was padded with a single '=',
                //  so it was replaced with '\r'. Now we have to
                //  prepend the boundary with '\n' to complete
                //  the line break.
                value += '\n';
            } else if (ending == EndingType.None) {
                //  The file's base64 was not padded at all,
                //  so we have to prepend the boundary with
                //  '\r\n' to create the line break.
                value += '\r\n';
            }
            //  Else:
            //  The file's base64 was padded with a double '=',
            //  so they were replaced with '\r\n'. We don't have to
            //  do anything to the boundary because there's a complete
            //  line break before it.
            
            value += '--' + Boundary + '--';
            
            blob valueBlob = blob.valueOf(value);
            
            return EncodingUtil.base64Encode(valueBlob);
        }
    
    /**
*  Write a key-value pair to the form's body.
*/
    private static string WriteBodyParameter(
        string key,
        string value) {
            string contentDisposition = 'Content-Disposition: form-data; name="' + key + '"';
            string contentDispositionCrLf = contentDisposition + '\r\n\r\n';
            blob contentDispositionCrLfBlob = blob.valueOf(contentDispositionCrLf);
            string contentDispositionCrLf64 = EncodingUtil.base64Encode(contentDispositionCrLfBlob);
            string content = SafelyPad(contentDisposition, contentDispositionCrLf64, '\r\n\r\n');
            string valueCrLf = value + '\r\n';
            blob valueCrLfBlob = blob.valueOf(valueCrLf);
            string valueCrLf64 = EncodingUtil.base64Encode(valueCrLfBlob);
            
            content += SafelyPad(value, valueCrLf64, '\r\n');
            
            return content;
        }
    
    /**
*  Helper enum indicating how a file's base64 padding was replaced.
*/
    private enum EndingType {
        Cr,
            CrLf,
            None
            }
}
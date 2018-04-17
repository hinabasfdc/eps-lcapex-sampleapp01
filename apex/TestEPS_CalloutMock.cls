@isTest
global class TestEPS_CalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        
        String httpEndpoint = req.getEndpoint();
        String httpMethod = req.getMethod();
        
        if (httpMethod.equals('POST')){
            if(httpEndpoint.equals('https://api.einstein.ai/v2/vision/predict')){
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"probabilities": [{"label": "beach","probability": 0.9602110385894775},{"label": "mountain","probability": 0.039788953959941864}],"object": "predictresponse"}');
                res.setStatusCode(200);
                return res;
            }else if (httpEndpoint.equals('https://api.einstein.ai/v2/language/sentiment')) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"probabilities": [{"label": "positive","probability": 0.77945083},{"label": "negative","probability": 0.18806243},{"label": "neutral","probability": 0.032486767}]}');
                res.setStatusCode(200);
                return res;            
            }else if (httpEndpoint.equals('https://api.einstein.ai/v2/oauth2/token')) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"access_token": "XLDZHXACW7DC45HQQLBZABCVFHWRT6KTBQNBIEAHCOYHCICM2Y34OBI46BD2K4XQQ2KLXI5HPHGT322G7MMKFOGE7534OGUMR6WC108","token_type": "Bearer","expires_in": 9999902}');
                res.setStatusCode(200);
                return res;   
            }          
        }
        
        return null;
    }
}
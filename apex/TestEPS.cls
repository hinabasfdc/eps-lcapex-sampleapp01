@isTest
private class TestEPS {
    
    //結果を格納するクラスのテスト
    @isTest static void testPredictionResult() {
        String samplejson = '{"probabilities": [{"label": "beach","probability": 0.9602110385894775},{"label": "mountain","probability": 0.039788953959941864}],"object": "predictresponse"}';
		EPS_PredictionResult ret = EPS_PredictionResult.parse(samplejson);
        System.assertEquals('beach', ret.probabilities[0].label);
        System.assertEquals(0.9602110385894775, ret.probabilities[0].probability);
        System.assertEquals('mountain', ret.probabilities[1].label);
        System.assertEquals(0.039788953959941864, ret.probabilities[1].probability);
    }

    //Vision API Call のテスト
    @isTest(SeeAllData=true) static void testGetVisionPrediction() {
        String predictiontype = 'IMAGECLASSIFICATION';
        String modelId = 'GeneralImageClassifier';
        String base64img = 'AAAABBBBCCCCDDDD';

        ContentVersion base64ContentKey = [SELECT Title, VersionData FROM ContentVersion where Title='einstein_platform' ORDER BY Title LIMIT 1];
        String eps_key = base64ContentKey.VersionData.tostring();

        ContentVersion base64ContentAccount = [SELECT Title, VersionData FROM ContentVersion where Title='einstein_account' ORDER BY Title LIMIT 1];
        String eps_account = base64ContentAccount.VersionData.tostring();        
        
		Test.setMock(HttpCalloutMock.class, new TestEPS_CalloutMock());
        Test.startTest();
        String ret = EPS_ApexController.getVisionPrediction(predictiontype, modelId, base64img, eps_account, eps_key);
        Test.stopTest();
    }

     //Language API Call のテスト
    @isTest(SeeAllData=true) static void testGetLanguagePrediction() {
        String predictiontype = 'SENTIMENT';
        String modelId = 'CommunitySentiment';
        String text = 'the presentation was great and I learned a lot';

        ContentVersion base64ContentKey = [SELECT Title, VersionData FROM ContentVersion where Title='einstein_platform' ORDER BY Title LIMIT 1];
        String eps_key = base64ContentKey.VersionData.tostring();

        ContentVersion base64ContentAccount = [SELECT Title, VersionData FROM ContentVersion where Title='einstein_account' ORDER BY Title LIMIT 1];
        String eps_account = base64ContentAccount.VersionData.tostring();        
        
        Test.setMock(HttpCalloutMock.class, new TestEPS_CalloutMock());
        Test.startTest();
        String ret = EPS_ApexController.getLanguagePrediction(predictiontype, modelId, text, eps_account, eps_key);
        Test.stopTest();
    }

}
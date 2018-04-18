({
    /*
     * 初期設定実行関数
     */
    doInit: function(component, event, helper) {
        //結果表示テーブルの列定義と設定
        var tablecolumn =  [
            { label: 'Label', fieldName: 'label', type: 'text' },
            { label: 'Probability', fieldName: 'probability', type: 'number' }
        ];
        component.set('v.imageclassification_result_columns', tablecolumn);
        component.set('v.sentiment_result_columns', tablecolumn);
    },
    
    /*
     * 画像ファイル読み込み実行関数
   */
    loadImage: function(component, event, helper) {
        //リサイズ処理をして画面に表示させる関数を呼出
        helper.drawImage(component, event.currentTarget.files[0]);
    },
    
    /*
     * 画像回転実行関数
     */
    rotateImage: function(component, event, helper) {
        //画像を回転させる処理をする関数を呼出
        helper.rotateImage(component);
    },
    
    /*
     * 画像領域にドラッグオーバーされた時の設定
     */
    onDragOver: function(component, event) {
        event.preventDefault();
    },
    
    /*
     * 画像領域にファイルがドロップされた時の実行関数
     */
    onDrop: function(component, event, helper) {
        event.stopPropagation();
        event.preventDefault();
        event.dataTransfer.dropEffect = 'copy';
        var files = event.dataTransfer.files;
        if (files.length>1) {
            return alert("解析したい画像ファイルをドロップしてください");
        }
        //リサイズ処理をして画面に表示させる関数を呼出
        helper.drawImage(component, files[0]);
    },
    
    /*
     * Image Classification でApex側の処理を呼び出す関数
     */
    getImageClassificationPrediction: function(component, event, helper) {
  
        //アカウントやキーが設定されていなければエラーメッセージを表示      
        if(component.get('v.EinsteinPlatformServices_Account') == undefined || component.get('v.EinsteinPlatformServices_Key') == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: "Error",
                message: "編集ページで Einstein Platform Services のアカウント、もしくはキーを設定してください",
                type: "error"
            });
            toastEvent.fire();
            return;
        }
  
        //画像が選択されていなければメッセージを表示      
        if(component.get('v.imagedata') == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: "Warning",
                message: "識別させたい画像を読み込ませてください",
                type: "warning"
            });
            toastEvent.fire();
            return;
        }
  
        //コンポーネント画面をローディング中に変更
        component.set('v.loaded', false);
        
        //Apex側の関数をセット
        var action = component.get("c.getVisionPrediction");
        
        //引数をセット
        action.setParams({
            predictiontype: "IMAGECLASSIFICATION",
            modelId: component.get('v.imageclassification_modelid'),
            //imageオブジェクトから抜き出した場合に、先頭に余分な文字列が入るので除去
            base64img: component.get('v.imagedata').match(/,(.*)$/)[1],
            eps_account: component.get('v.EinsteinPlatformServices_Account'),
            eps_key: component.get('v.EinsteinPlatformServices_Key')
        });
        
        //実行が完了した場合の処理をセット
        action.setCallback(this, function(ret) {
            var results = ret.getReturnValue();
            //予測・解析の返り値が存在する場合にテーブル表示
            if(JSON.parse(results).probabilities){
                component.set('v.imageclassification_result_data', JSON.parse(results).probabilities);
            }
            //返り値をそのまま表示
            component.set('v.imageclassification_result_rawtext', results);
            //ローディング中の画面を解除
            component.set('v.loaded', true);
        });
        //呼び出し実行キューに入れる
        $A.enqueueAction(action); 
    },
    
    /*
     * Sentiment でApex側の処理を呼び出す関数
     */
    getSentiment : function(component, event, helper) {
  
        //アカウントやキーが設定されていなければエラーメッセージを表示      
        if(component.get('v.EinsteinPlatformServices_Account') == undefined || component.get('v.EinsteinPlatformServices_Key') == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: "Error",
                message: "編集ページで Einstein Platform Services のアカウント、もしくはキーを設定してください",
                type: "error"
            });
            toastEvent.fire();
            return;
        }
        
        //テキストが入力されていなければメッセージを表示      
        if(component.get('v.sentiment_text') == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: "Warning",
                message: "識別させたいテキストを入力してください",
                type: "warning"
            });
            toastEvent.fire();
            return;
        }
        
        //コンポーネント画面をローディング中に変更
        component.set('v.loaded', false);
        
        //Apex側の関数をセット
        var action = component.get("c.getLanguagePrediction");
        
        //引数をセット
        action.setParams({
            predictiontype: 'SENTIMENT',
            modelId: component.get('v.sentiment_modelid'),
            text: component.get('v.sentiment_text'),
            eps_account: component.get('v.EinsteinPlatformServices_Account'),
            eps_key: component.get('v.EinsteinPlatformServices_Key')
        });
        
        //実行が完了した場合の処理をセット
        action.setCallback(this, function(ret) {
            var results = ret.getReturnValue();
            //予測・解析の返り値が存在する場合にテーブル表示
            if(JSON.parse(results).probabilities){
                component.set('v.sentiment_result_data', JSON.parse(results).probabilities);
            }
            //返り値をそのまま表示
            component.set('v.sentiment_result_rawtext', results);
            //ローディング中の画面を解除
            component.set('v.loaded', true);
        });
        //呼び出し実行キューに入れる
        $A.enqueueAction(action);         
    },
  })
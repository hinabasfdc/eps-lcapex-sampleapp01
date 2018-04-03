({
  /*
   * 指定したサイズより大きい画像の場合はリサイズして表示する関数
   */
  drawImage : function(component, file) {
      //定義値を取得
      var maximagesize = component.get('v.maximagesize');
      
      //処理用オブジェクト生成
      var reader = new FileReader();
      var image = new Image();
      
      //ファイル読み込み後のアクションを定義
      reader.onload = function(evt) {
          
          //イメージ読み込み後のアクションを定義
          image.onload = function() {
              
              //HTML5 CANVASオブジェクトを生成
              var canvas = document.createElement('canvas');
              var ctx = canvas.getContext('2d');
              
              //読み込まれたイメージのサイズを取得
              var w = image.width;
              var h = image.height;
              
              //最大サイズより大きければリサイズする
              if (w > maximagesize || h > maximagesize) {
                  var ratio = '';
                  if (w > h) {
                      ratio = maximagesize / w;
                      w = maximagesize;
                      h = h * ratio;
                  } else {
                      ratio = maximagesize / h;
                      h = maximagesize;
                      w = w * ratio;
                  }
              }
              
              //CANVASのサイズをリサイズ後のサイズに合わせた後に描画実行
              canvas.width = w;
              canvas.height = h;
              ctx.drawImage(image, 0, 0, w, h);
              
              //表示用のイメージオブジェクトに、リサイズした画像データを転記
              component.set("v.imagedata", canvas.toDataURL('image/jpeg'));
          }
          //画像ファイルをimgオブジェクトのソースに指定
          image.src = evt.target.result;
      }
      //ファイルを読み込み
      reader.readAsDataURL(file);			
  },

  /*
   * 画像を回転させる関数
   */
  rotateImage: function(component) {
      //処理用オブジェクト生成
      var image = new Image();

      //HTML5 CANVASオブジェクトを生成
      var canvas = document.createElement('canvas');
      var ctx = canvas.getContext('2d');

      //イメージ読み込み後のアクションを定義
      image.onload = function() {
    //サイズを設定
          canvas.width = image.height;
          canvas.height = image.width;

          //回転処理
          ctx.clearRect(0, 0, canvas.width, canvas.height);
          ctx.rotate((90 * Math.PI) / 180);
          ctx.translate(0, -image.height);
          ctx.drawImage(image, 0, 0);
          
          //表示用のイメージオブジェクトに、回転させた画像データを転記
          component.set("v.imagedata", canvas.toDataURL('image/jpeg'));
      }
      //画像データを表示データから読み込み
      image.src = component.get("v.imagedata");
  },
})
import neko.Lib;
import neko.tls.Socket;
import neko.tls.Verify;

class ClosableBytesOutput extends haxe.io.BytesOutput {

   public function new() super()

   override public function close() {
      super.close();
      onClose();
   }

   dynamic public function onClose() {}
}

class VerifyingSocket extends Socket {

   public function new(hostname: String) {
      super();
      this.hostname = hostname;
   }

   override function onHandshakeResult(verify: Verify, peer_name: String) {
      switch (verify) {
         case V_Err(code):
            throw "verify error, code = " + code;

         case V_Ok:
            if (hostname != peer_name) {
               throw "verify error, connected to " + hostname + " but got " + peer_name;
            }
      }
   }

   var hostname: String;

}

class TestHttps {
	static function main() {

      var args = neko.Sys.args();

      if (args.length < 1) {
         Lib.println("Usage: TestHttps.n <url>");
         return;
      }

      var parts = args[0].split("/");
      var hostname = parts.shift();
      var url = hostname + ":443" + 
            if (parts.length == 0) ""
            else "/" + parts.join("/")
            ;

      Lib.println("Requesting from URL: " + url);

		var https: haxe.Http = new haxe.Http(url);
		
      var output  = new ClosableBytesOutput();
		
      output.onClose = function() {
			https.onData(
               Lib.stringReference(output.getBytes()) );
		};

		https.onData=function(data : String) {
			trace ("https.Data:\n"+data+"\n");			
		}
		
      https.onError=function(msg : String) {
			trace ("https.Error:"+msg+"\n");
		}
		
      https.onStatus=function(status : Int){
			trace ("https.Status:"+status+"\n");
		}
		
      trace("Before async request");
		https.customRequest(false, output, new VerifyingSocket(hostname) );
		trace("After async request");		
	}
}

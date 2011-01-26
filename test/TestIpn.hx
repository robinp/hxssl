import neko.tls.Socket;
import neko.tls.Verify;
import neko.net.Host;
import neko.Lib;
import neko.Web;

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

/// Toy code for PayPal IPN processing. 
///
class TestIpn {

   static var ipn_test_host = "www.sandbox.paypal.com";
   static var ipn_real_host = "www.paypal.com";

   static var ipn_host = ipn_test_host;

   static var ipn_url = ipn_host + ":443/cgi-bin/webscr";

   static function main() {

      if (!Web.isModNeko) {
         Lib.println("module supposed to run under mod_neko");
         return;
      }

      var print = Web.logMessage;

      print("IPN processing");

      var params = Web.getParams();
	   var https: haxe.Http = new haxe.Http(ipn_url);

      https.setParameter("cmd", "_notify-validate");
      for (k in params.keys()) {
         print("IPN param: " + k + " = "  + params.get(k));
         https.setParameter(k, params.get(k));
      }

      var output  = new ClosableBytesOutput();
		
      output.onClose = function() {
         print("IPN closing");
			https.onData(
               Lib.stringReference(output.getBytes()) );
		};

		https.onData = function(data : String) {
			print("IPN data: " + data);
		}
		
      https.onError = function(msg : String) {
			print("IPN error: " + msg);
		}
		
      https.onStatus=function(status : Int){
			print("IPN status: " + status);
		}

		https.customRequest(true, output, new VerifyingSocket(ipn_host) );
   }

}

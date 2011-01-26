package neko.tls;

enum Verify {
   V_Ok;
   V_Err(code: Int);
}

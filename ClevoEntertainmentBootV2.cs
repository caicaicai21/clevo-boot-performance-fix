using System;
using System.IO;
using System.Diagnostics;
using System.Threading;
using System.Runtime.InteropServices;
class ClevoEntertainmentBootV2 {
 const string Dll = @"C:\Program Files (x86)\ControlCenter\InsydeDCHU.dll";
 static Stopwatch clock = Stopwatch.StartNew();
 static string log = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "boot-v2.log");
 static void Log(string s) { File.AppendAllText(log, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " elapsedMs=" + clock.ElapsedMilliseconds + " " + s + Environment.NewLine); }
 [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Unicode)] static extern IntPtr OpenSCManager(string machine,string database,uint access);
 [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Unicode)] static extern IntPtr OpenService(IntPtr manager,string name,uint access);
 [DllImport("advapi32.dll", SetLastError=true)] static extern bool QueryServiceStatus(IntPtr service,out ServiceStatus status);
 [DllImport("advapi32.dll")] static extern bool CloseServiceHandle(IntPtr handle);
 [StructLayout(LayoutKind.Sequential)] struct ServiceStatus { public uint type,state,controls,win32Exit,specificExit,checkpoint,waitHint; }
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr LoadLibraryExW(string path,IntPtr file,uint flags);
 [DllImport("kernel32.dll",CharSet=CharSet.Ansi,ExactSpelling=true,SetLastError=true)] static extern IntPtr GetProcAddress(IntPtr module,string name);
 [DllImport("kernel32.dll")] static extern bool FreeLibrary(IntPtr module);
 [DllImport("kernel32.dll")] static extern ulong GetTickCount64();
 [UnmanagedFunctionPointer(CallingConvention.Winapi)] delegate int SetData(int command,[In] byte[] data,int length);
 static int Main(string[] args) {
  // No device operations, DLL loading, or logging in self-test mode.
  if(args.Length==1 && args[0]=="--self-test") { Console.WriteLine("x64="+Environment.Is64BitProcess+"; self-test only; no hardware operations."); return Environment.Is64BitProcess?0:1; }
  IntPtr manager=IntPtr.Zero,service=IntPtr.Zero,module=IntPtr.Zero;
  try {
   Log("START pid="+Process.GetCurrentProcess().Id+" uptimeMs="+GetTickCount64());
   if(args.Length!=0) throw new Exception("Unexpected arguments.");
   if(!Environment.Is64BitProcess) throw new Exception("Requires x64.");
   Log("DRIVER_CHECK_BEGIN");
   manager=OpenSCManager(null,null,1);if(manager==IntPtr.Zero) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
   service=OpenService(manager,"AcpiBridge",4);if(service==IntPtr.Zero) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
   bool ready=false;
   for(int i=0;i<30;i++) { ServiceStatus s;if(!QueryServiceStatus(service,out s)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error()); if(s.state==4){ready=true;break;} Thread.Sleep(1000); }
   if(!ready) throw new Exception("Driver not running within 30 seconds; no request issued.");
   Log("DRIVER_READY");
   Log("DLL_LOAD_BEGIN");
   module=LoadLibraryExW(Dll,IntPtr.Zero,0x1100);if(module==IntPtr.Zero) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
   Log("DLL_LOAD_END");
   IntPtr address=GetProcAddress(module,"SetDCHU_Data");if(address==IntPtr.Zero) throw new Exception("Missing export.");
   SetData set=(SetData)Marshal.GetDelegateForFunctionPointer(address,typeof(SetData));
   Log("MODE_REQUEST_BEGIN entertainment=3 command=121 packet=03-00-00-19");
   int result=set(121,new byte[]{3,0,0,25},4);
   Log("MODE_REQUEST_END return="+result+"; saved preferences unchanged; not proof of frequency recovery");
   return result==0?0:2;
  } catch(Exception e) {try{Log("FAILED "+e.ToString());}catch{} return 1; }
  finally {if(module!=IntPtr.Zero)FreeLibrary(module);if(service!=IntPtr.Zero)CloseServiceHandle(service);if(manager!=IntPtr.Zero)CloseServiceHandle(manager);}
 }
}

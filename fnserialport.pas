unit FnSerialPort;

interface

uses
  Windows, Variants, Classes, Registry;

  function GetSerialPortFriendlyName(port:string; key:string =
    '\System\CurrentControlSet\Enum\'): string; overload;
  function GetSerialPortFriendlyName(PortList:TStringList): TStringList; overload;
  function GetSerialPortList: TStringList;

implementation

function GetSerialPortFriendlyName(port:string; key:string =
  '\System\CurrentControlSet\Enum\'): string; overload;
{ Mendapatkan FriendlyName dari Serial Port.
  Source : http://patotech.blogspot.com/2012/04/enumerate-com-ports-in-windows-with.html
  Uses: Registry }
var
  r: TRegistry;
  k: TStringList;
  i: Integer;
  ck, rs: string;
begin
  r := TRegistry.Create;
  k := TStringList.Create;
  r.RootKey := HKEY_LOCAL_MACHINE;
  r.OpenKeyReadOnly(key);
  r.GetKeyNames(k);
  r.CloseKey;
  try
    for i := 0 to k.Count - 1 do
    begin
      ck := key + k[i] + '\'; // current key
      // looking for "PortName" stringvalue in "Device Parameters" subkey
      if r.OpenKeyReadOnly(ck + 'Device Parameters') then
      begin
        if r.ReadString('PortName') = port then
        begin
          //Memo1.Lines.Add('--> ' + ck);
          r.CloseKey;
          r.OpenKeyReadOnly(ck);
          rs := r.ReadString('FriendlyName');
          Break;
        end // if r.ReadString('PortName') = port ...
      end  // if r.OpenKeyReadOnly(ck + 'Device Parameters') ...
      // keep looking on subkeys for "PortName"
      else // if not r.OpenKeyReadOnly(ck + 'Device Parameters') ...
      begin
        if r.OpenKeyReadOnly(ck) and r.HasSubKeys then
        begin
          rs := GetSerialPortFriendlyName(port, ck);
          if rs <> '' then Break;
        end; // if not (r.OpenKeyReadOnly(ck) and r.HasSubKeys) ...
      end; // if not r.OpenKeyReadOnly(ck + 'Device Parameters') ...
    end; // for i := 0 to k.Count - 1 ...
    result := rs;
  finally
    r.Free;
    k.Free;
  end;
end;

function GetSerialPortFriendlyName(PortList:TStringList): TStringList; overload;
{ Sama dengan diatas, hanya parameter dan result TStringList }
var
  i: integer;
begin
  Result := TStringList.Create;
  for i := 0 to PortList.Count - 1 do
    Result.Add(GetSerialPortFriendlyName(PortList[i]));
end;

function GetSerialPortList: TStringList;
{ Mendapatkan List Serial Port yang aktif.
  Source : http://patotech.blogspot.com/2012/04/enumerate-com-ports-in-windows-with.html
  Uses: Registry }
var
  reg: TRegistry;
  vn: TStringList;
  n: integer;
  PortN: string;
begin
  Result := TStringList.Create;
  vn := TStringList.Create;
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    if reg.OpenKeyReadOnly('HARDWARE\DEVICEMAP\SERIALCOMM') then
    begin
      reg.GetValueNames(vn);
      for n := 0 to vn.Count - 1 do begin
        PortN := reg.ReadString(vn[n]);
        Result.Add(PortN);
      end; // for n := 0 to l.Count - 1 ...
    end; // if reg.OpenKeyReadOnly('HARDWARE\DEVICEMAP\SERIALCOMM') ...
  finally
    reg.Free;
    vn.Free;
  end;
end;

end.

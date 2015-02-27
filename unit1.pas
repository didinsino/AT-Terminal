unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, vsComPort, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, Menus, IniFiles, vsComPortbase, Windows, SHFolder;

type

  { TForm1 }

  TForm1 = class(TForm)
    cbTmp: TComboBox;
    eCmd: TEdit;
    mnConn: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    mmCmd: TMemo;
    Panel1: TPanel;
    pnArrow: TPanel;
    PopupMenu1: TPopupMenu;
    vsComPort1: TvsComPort;
    procedure eCmdKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure eCmdKeyPress(Sender: TObject; var Key: char);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MenuItem10Click(Sender: TObject);
    procedure mnConnClick(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
    procedure mmCmdChange(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure vsComPort1RxData(Sender: TObject);
  private
    { private declarations }
  public
    function ConnectToPort(dev, br: string): boolean;
  end;

var
  Form1: TForm1;
  CFG_PATH, DEV_PORT, DEV_BAUDRATE: string;
  prevKeyDown: Word;

const
  APP_TITLE = 'AT Terminal';

implementation

uses fnserialport, usetup;

{$R *.lfm}

{ TForm1 }

function GetSpecialFolderPath(folder : integer) : string;
const
  SHGFP_TYPE_CURRENT = 0;
var
  path: array [0..MAX_PATH] of char;
begin
  if SUCCEEDED(SHGetFolderPath(0,folder,0,SHGFP_TYPE_CURRENT,@path[0])) then
    Result := path else
    Result := '';
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  if not vsComPort1.Active then
    fSetup.ShowModal;
  mmCmdChange(nil);
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  ini: TIniFile;
begin
  if vsComPort1.Active then vsComPort1.Close;
  // Save config
  ini:=TIniFile.Create(CFG_PATH + 'lastconn');
  try
    ini.WriteString('conn', 'device', DEV_PORT);
    ini.WriteString('conn', 'baudrate', DEV_BAUDRATE);
  finally
    ini.Free;
  end;
  // save cmd history
  mmCmd.Lines.SaveToFile(CFG_PATH+'cmdhistory');
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  ini: TIniFile;
begin
  Application.Title:=APP_TITLE;
  Self.Caption:=APP_TITLE;
  // load config
  ini:=TIniFile.Create(CFG_PATH + 'lastconn');
  try
    DEV_PORT := ini.ReadString('conn', 'device', '');
    DEV_BAUDRATE := ini.ReadString('conn', 'baudrate', '9600');
  finally
    ini.Free;
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  PortList: TStringList;
begin
  // if last used port exist, connect automatically
  PortList := GetSerialPortList;
  try
    if PortList.IndexOf(DEV_PORT) > -1 then
      ConnectToPort(DEV_PORT, DEV_BAUDRATE);
  finally
    PortList.Free;
  end;
  // load cmd history
  if FileExists(CFG_PATH+'cmdhistory') then
    mmCmd.Lines.LoadFromFile(CFG_PATH+'cmdhistory');
  pnArrow.Visible:=False;
  cbTmp.Items.Clear;
  eCmd.Clear;
end;

procedure TForm1.MenuItem10Click(Sender: TObject);
begin
  fSetup.ShowModal;
end;

procedure TForm1.mnConnClick(Sender: TObject);
begin
  Self.Caption:=APP_TITLE;
  if vsComPort1.Active then
    vsComPort1.Close else
    ConnectToPort(DEV_PORT, DEV_BAUDRATE);
end;

procedure TForm1.MenuItem8Click(Sender: TObject);
begin
  mmCmd.Clear;
  eCmd.SetFocus;
end;

procedure TForm1.mmCmdChange(Sender: TObject);
var
  lstL: integer;
begin
  mmCmd.SelStart := Length(mmCmd.Text);
  mmCmd.Perform(EM_SCROLLCARET, 0, 0);
  lstL:=mmCmd.Lines.Count-1;
  if Trim(mmCmd.Lines[lstL]) = '>' then begin
    if Trim(mmCmd.Lines[lstL-1]) = '' then
      mmCmd.Lines.Delete(lstL-1);
    pnArrow.Visible:=True;
  end;
end;

procedure TForm1.PopupMenu1Popup(Sender: TObject);
begin
  if vsComPort1.Active then begin
    mnConn.Enabled:=True;
    mnConn.Caption:='Disconnect';
  end else begin
    mnConn.Enabled:=False;
    if DEV_PORT <> '' then begin
      mnConn.Caption:='Connect to '+DEV_PORT;
      mnConn.Enabled:=True;
    end;
  end;
end;

procedure TForm1.eCmdKeyPress(Sender: TObject; var Key: char);
var
  x, lstL: integer;
  lstS: string;
begin
  if (Key = #13) or (Key = #26) then begin
    lstL := mmCmd.Lines.Count-1;
    lstS := Trim(mmCmd.Lines[lstL]);
    if Key = #13 then begin
      if Trim(eCmd.Text) = '' then Exit;
      if not vsComPort1.Active then begin
        MessageDlg('Please connect to device first!', mtInformation, [mbOk], 0);
        Exit;
      end;
      Sleep(10);
      if LeftStr(lstS, 1) = '>' then begin
        if lstS = '>' then mmCmd.Lines.Delete(lstL);
        vsComPort1.WriteData(eCmd.Text + #13);
      end else begin
        if mmCmd.Lines.Count > 0 then
          mmCmd.Lines.Add(sLineBreak);
        vsComPort1.WriteData(eCmd.Text + sLineBreak);
        x := cbTmp.Items.IndexOf(eCmd.Text);
        if x > -1 then cbTmp.Items.Delete(x);
        cbTmp.Items.Add(eCmd.Text);
        cbTmp.ItemIndex := -1;
      end;
    end else

    if (Key = #26) and (pnArrow.Visible) then begin // ctrl+z
      if Trim(eCmd.Text) <> '' then begin
        if lstS = '>' then mmCmd.Lines.Delete(lstL);
        Sleep(10);
        vsComPort1.WriteData(eCmd.Text + #13);
      end;
      Sleep(10);
      vsComPort1.WriteData(#26);
      pnArrow.Visible:=False;
      eCmd.Clear;
    end;
    eCmd.Clear;
  end;
end;

procedure TForm1.eCmdKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = 38) or (Key = 40) then begin
    if Key = 38 then begin // Up arrow
      if cbTmp.ItemIndex = -1 then
        cbTmp.ItemIndex := cbTmp.Items.Count -1 else
      if cbTmp.ItemIndex > 0 then
          cbTmp.ItemIndex := cbTmp.ItemIndex - 1;
      eCmd.Text := cbTmp.Text;
    end else
    if Key = 40 then begin // Down arrows
      if (cbTmp.ItemIndex < (cbTmp.Items.Count-1)) and (cbTmp.ItemIndex > -1) then begin
        cbTmp.ItemIndex := cbTmp.ItemIndex + 1;
        eCmd.Text := cbTmp.Text;
      end else
        eCmd.Text:='';
    end;
    Key := 0;
    eCmd.SelStart := Length(eCmd.Text);
  end;
  prevKeyDown := Key;
end;

procedure TForm1.vsComPort1RxData(Sender: TObject);
var
  str: string;
begin
  str:=vsComPort1.ReadData;
  mmCmd.Text:=mmCmd.Text + str;
end;

function TForm1.ConnectToPort(dev, br: string): boolean;
begin
  Result:=False;
  if vsComPort1.Active then vsComPort1.Close;
  vsComPort1.Device:=dev;
  vsComPort1.BaudRate:=StrToBaudRate(br);
  try
    vsComPort1.Open;
    DEV_PORT:=dev;
    DEV_BAUDRATE:=br;
    Self.Caption:=APP_TITLE + ' - Connected to '+dev;
    Result:=True;
  except
    Self.Caption:=APP_TITLE;
    MessageDlg('Error opening '+dev, mtError, [mbOk] ,0);
  end
end;

initialization
  CFG_PATH := GetSpecialFolderPath(CSIDL_LOCAL_APPDATA)+'\'+APP_TITLE+'\';

end.


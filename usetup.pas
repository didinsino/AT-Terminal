unit usetup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, vsComPortbase;

type

  { TfSetup }

  TfSetup = class(TForm)
    Button2: TButton;
    cbDevice: TComboBox;
    vCbDevice: TComboBox;
    cbBaud: TComboBox;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure vCbDeviceChange(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fSetup: TfSetup;

implementation

uses fnserialport, unit1;

{$R *.lfm}

{ TfSetup }

procedure TfSetup.Button2Click(Sender: TObject);
begin
  Form1.ConnectToPort(cbDevice.Text, cbBaud.Text);
  Close;
end;

procedure TfSetup.FormCreate(Sender: TObject);
var
  br: TBaudRate;
begin
  // get list of baud rates
  cbBaud.Items.Clear;
  for br := Low(TBaudRate) to High(TBaudRate) do begin
    cbBaud.Items.Add(BaudRateStrings[br]);
  end;
end;

procedure TfSetup.FormShow(Sender: TObject);
var
  PortList, PortFNList: TStringList;
begin
  Application.ProcessMessages;
  // get attached com port
  PortList := GetSerialPortList;
  PortFNList := GetSerialPortFriendlyName(PortList);
  try
    cbDevice.Items.Assign(PortList);
    vCbDevice.Items.Assign(PortFNList);
  finally
    PortFNList.Free;
    PortList.Free;
  end;
  vCbDevice.ItemIndex:=cbDevice.Items.IndexOf(DEV_PORT);
  cbDevice.ItemIndex:=cbDevice.Items.IndexOf(DEV_PORT);
  cbBaud.ItemIndex:=cbBaud.Items.IndexOf(DEV_BAUDRATE);
end;

procedure TfSetup.vCbDeviceChange(Sender: TObject);
begin
  cbDevice.ItemIndex:=vCbDevice.ItemIndex;
end;

end.


unit ustartup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfStartup }

  TfStartup = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fStartup: TfStartup;
  SC_PATH: string;

implementation

uses unit1;

{$R *.lfm}

{ TfStartup }

procedure TfStartup.Button1Click(Sender: TObject);
begin
  Memo1.Lines.SaveToFile(SC_PATH);
  Close;
end;

procedure TfStartup.FormCreate(Sender: TObject);
begin
  SC_PATH := CFG_PATH + 'startupcmd';
end;

procedure TfStartup.FormShow(Sender: TObject);
begin
  if FileExists(SC_PATH) then
    Memo1.Lines.LoadFromFile(SC_PATH);
end;

end.


unit uFrmSplash;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uFrmBase, Skia, Skia.FMX, FMX.Layouts, Router4D, Router4D.Interfaces;

type
  TFrmSplash = class(TFrmBase, iRouter4DComponent)
    SkAnimatedImage1: TSkAnimatedImage;
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure CreateRouters;
    { Private declarations }
  public
    { Public declarations }

    function  Render : TFmxObject;
    procedure UnRender;
  end;

var
  FrmSplash: TFrmSplash;

implementation

uses
  uFrmHome;

{$R *.fmx}

{ TFrmSplash }

procedure TFrmSplash.FormCreate(Sender: TObject);
begin
  inherited;

  CreateRouters;

end;

function TFrmSplash.Render: TFmxObject;
begin
  Result := mainLayout;
end;

procedure TFrmSplash.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  TRouter4D.Link.&To('Home');
end;

procedure TFrmSplash.UnRender;
begin

end;

procedure TFrmSplash.CreateRouters;
begin
  TRouter4D.Switch.Router('Home', TFrmHome);
end;

end.

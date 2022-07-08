unit uFrmHome;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uFrmBase, FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, Skia, Skia.FMX,
  Router4D, Router4D.Interfaces;

type
  TFrmHome = class(TFrmBase, iRouter4DComponent)
    rectAcessarCatalogo: TRectangle;
    lblAcessar: TLabel;
    logoSvg: TSkSvg;
    procedure FormCreate(Sender: TObject);
    procedure rectAcessarCatalogoClick(Sender: TObject);
  private
    procedure CreateRouters;
    { Private declarations }
  public
    { Public declarations }

    function  Render : TFmxObject;
    procedure UnRender;
  end;

var
  FrmHome: TFrmHome;

implementation

{$R *.fmx}

uses uFrmPrincipal;

{ TFrmHome }

procedure TFrmHome.FormCreate(Sender: TObject);
begin
  inherited;

  CreateRouters;
end;

procedure TFrmHome.rectAcessarCatalogoClick(Sender: TObject);
begin
  TRouter4D.Link.&To('Principal');
end;

function TFrmHome.Render: TFmxObject;
begin
    Result := mainLayout;
end;

procedure TFrmHome.UnRender;
begin

end;

procedure TFrmHome.CreateRouters;
begin
  TRouter4D.Switch.Router('Principal', tfrmprincipal);
end;

end.

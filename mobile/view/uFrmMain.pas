unit uFrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  Router4D, Router4D.Interfaces, System.Math;

type
  TFrmMain = class(TForm)
    lytIndex: TLayout;
    vScroll: TVertScrollBox;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormFocusChanged(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormVirtualKeyboardHidden(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardShown(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
  private
    FKBBounds: TRectF;
    FNeedOffset: Boolean;

    procedure RegisterRoutes;
    { Private declarations }
  public
    { Public declarations }

    procedure Animation( aLayout : TFMXObject );

    {$IFNDEF MSWINDOWS}
    procedure CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
    procedure UpdateKBBounds;
    procedure RestorePosition;
    {$ENDIF}
  end;

var
  FrmMain: TFrmMain;

implementation

uses
  uFrmSplash;

{$R *.fmx}

procedure TFrmMain.Animation(aLayout: TFMXObject);
var
  aHeight : Single;
begin
  //Animation 1 -----------------
  TLayout(aLayout).Opacity := 0;
  TLayout(aLayout).AnimateFloat('Opacity', 1, 0.9);
  //----------------------------
  //Animation 2 ----------------------
//  aHeight := TLayout(aLayout).Height;
//  TLayout(aLayout).Height := 0;
//  TLayout(aLayout).Align := TAlignLayout.None;
//  TLayout(aLayout).AnimateFloat('Height', aHeight, 0.9);
//  TLayout(aLayout).Opacity := 0;
//  TLayout(aLayout).AnimateFloat('Opacity', 1, 0.9);
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  {$IFNDEF MSWINDOWS}
  VKAutoShowMode := TVKAutoShowMode.Always;
  vScroll.OnCalcContentBounds := CalcContentBoundsProc;
  {$ENDIF}
end;

procedure TFrmMain.FormFocusChanged(Sender: TObject);
begin
  {$IFNDEF MSWINDOWS}
  UpdateKBBounds;
  {$ENDIF}
end;

procedure TFrmMain.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
    if Key = vkReturn then
    begin
       Key := vkTab;
       KeyDown(Key, KeyChar, Shift);
    end;
end;

procedure TFrmMain.FormShow(Sender: TObject);
begin
  RegisterRoutes;
  TRouter4D.Render<TFrmSplash>.SetElement(lytIndex, lytIndex);
  TRouter4D.Link.Animation(Animation);
end;

procedure TFrmMain.FormVirtualKeyboardHidden(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
    {$IFNDEF MSWINDOWS}
    FKBBounds.Create(0, 0, 0, 0);
    FNeedOffset := False;
    RestorePosition;
    {$ENDIF}
end;

procedure TFrmMain.FormVirtualKeyboardShown(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
    {$IFNDEF MSWINDOWS}
    FKBBounds := TRectF.Create(Bounds);
    FKBBounds.TopLeft := ScreenToClient(FKBBounds.TopLeft);
    FKBBounds.BottomRight := ScreenToClient(FKBBounds.BottomRight);
    UpdateKBBounds;
    {$ENDIF}
end;

procedure TFrmMain.RegisterRoutes;
begin
  TRouter4D.Switch.Router('Splash', TFrmSplash);
end;

{$IFNDEF MSWINDOWS}
procedure TFrmMain.UpdateKBBounds;
var
    LFocused : TControl;
    LFocusRect: TRectF;
begin
    FNeedOffset := False;
    if Assigned(Focused) then
    begin
        LFocused := TControl(Focused.GetObject);
        LFocusRect := LFocused.AbsoluteRect;
        LFocusRect.Offset(vScroll.ViewportPosition);
        if (LFocusRect.IntersectsWith(TRectF.Create(FKBBounds))) and
           (LFocusRect.Bottom > FKBBounds.Top) then
        begin
          FNeedOffset := True;
          lytIndex.Align := TAlignLayout.Horizontal;
          vScroll.RealignContent;
          Application.ProcessMessages;
          vScroll.ViewportPosition :=
            PointF(vScroll.ViewportPosition.X,
                   LFocusRect.Bottom - FKBBounds.Top);
        end;
    end;
    if not FNeedOffset then
        RestorePosition;
end;

procedure TFrmMain.RestorePosition;
begin
    vScroll.ViewportPosition := PointF(vScroll.ViewportPosition.X, 0);
    lytIndex.Align := TAlignLayout.Client;
    vScroll.RealignContent;
end;

procedure TFrmMain.CalcContentBoundsProc(Sender: TObject;
                                       var ContentBounds: TRectF);
begin
    if FNeedOffset and (FKBBounds.Top > 0) then
    begin
        ContentBounds.Bottom := Max(ContentBounds.Bottom,
                                    2 * ClientHeight - FKBBounds.Top);
    end;
end;
{$ENDIF}

end.

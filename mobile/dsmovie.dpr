program dsmovie;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Types,
  Skia.FMX,
  uFrmBase in 'view\uFrmBase.pas' {FrmBase},
  uFrmSplash in 'view\uFrmSplash.pas' {FrmSplash},
  uFrmMain in 'view\uFrmMain.pas' {FrmMain},
  uFrmHome in 'view\uFrmHome.pas' {FrmHome},
  uFrmPrincipal in 'view\uFrmPrincipal.pas' {FrmPrincipal},
  uFrmFilme in 'view\uFrmFilme.pas' {FrmFilme},
  Utils in 'Infra\Utils.pas';

{$R *.res}

begin
  GlobalUseMetal := True;
  GlobalUseSkiaRasterWhenAvailable := False;
  GlobalUseSkia := True;

  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  Application.Initialize;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.

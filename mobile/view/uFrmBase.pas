unit uFrmBase;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  System.Math;

type
  TFrmBase = class(TForm)
    vScroll: TVertScrollBox;
    mainLayout: TLayout;
    StyleBook: TStyleBook;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  private

    { Private declarations }
  public
    useBackButton : Boolean;

    { Public declarations }
  end;

var
  FrmBase: TFrmBase;

implementation

{$R *.fmx}

procedure TFrmBase.FormCreate(Sender: TObject);
begin
    useBackButton := true;
end;

procedure TFrmBase.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
    if NOT useBackButton then
        if Key = vkHardwareBack then
        begin
            Key := 0;
        end;
end;

end.

unit uFrmPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uFrmBase, FMX.Layouts, Skia, FMX.Controls.Presentation, Skia.FMX, FMX.Edit,
  FMX.Objects, Router4D, Router4D.Interfaces, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView, REST.Client,
  REST.Types, System.JSON, System.Net.HttpClient, RESTRequest4D, Router4D.Props;

type
  TFrmPrincipal = class(TFrmBase, iRouter4DComponent)
    logoSvg: TSkSvg;
    Label1: TLabel;
    rectBuscar: TRectangle;
    SkSvg1: TSkSvg;
    editBuscar: TEdit;
    lvFilmes: TListView;
    Image1: TImage;
    rectCarregando: TRectangle;
    loading: TSkAnimatedImage;
    Layout1: TLayout;
    refresh: TSkSvg;
    procedure FormCreate(Sender: TObject);
    procedure lvFilmesPaint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
    procedure editBuscarChange(Sender: TObject);
    procedure lvFilmesItemClick(const Sender: TObject;
      const AItem: TListViewItem);
  private
    TotalPages : Integer;

    procedure AddFilmes(ListView: TListView; IdFilme, NomeFilme, QtdeAvaliacoes,
      Nota: String; Image : TImage);
    function GetFilmes(Pagina : String='0'; Title : String='') : String;
    procedure ListarFilmes(IndClear: Boolean; Pagina: string='0'; Title : String='');
    procedure TThreadEndListarFilmes(Sender: TObject);
    procedure BuscarFromUrlMultiPlatform(Url: string;
      out Stream: TBytesStream);
    { Private declarations }
    procedure CreateRouters;
  public
    { Public declarations }

    function  Render : TFmxObject;
    procedure UnRender;
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

uses
  uFrmFilme, Utils;

{$R *.fmx}

procedure TFrmPrincipal.editBuscarChange(Sender: TObject);
begin
  ListarFilmes(True, '0', editBuscar.Text);
end;

Function TFrmPrincipal.GetFilmes(Pagina : String='0'; Title : String='') : String;
var
  LResponse : IResponse;
begin
  if Title <> '' then
  begin
    LResponse := TRequest.New.BaseURL(Utils.URL_BASE)
      .Resource('movies/title')
      .AddParam('title', Title)
      .AddParam('size', '10')
      .AddParam('page', Pagina)
      .AddParam('sort', 'title')
      .Accept('application/json')
      .Get;
  end
  else
  begin
    LResponse := TRequest.New.BaseURL(Utils.URL_BASE)
      .Resource('movies')
      .AddParam('size', '10')
      .AddParam('page', Pagina)
      .AddParam('sort', 'title')
      .Accept('application/json')
      .Get;
  end;

  if LResponse.StatusCode in [200, 201, 203] then
    Result := LResponse.Content;
end;

procedure TFrmPrincipal.ListarFilmes(IndClear: Boolean; Pagina: string='0'; Title : String='');
var
  Thread : TThread;
begin
  // Em processamento....
  if lvFilmes.TagString = 'processando' then
      exit;

  lvFilmes.TagString := 'processando';

  //--------------------------------------------

  if IndClear then
  begin
      lvFilmes.ScrollTo(0);
      lvFilmes.Tag := 0;
      lvFilmes.Items.Clear;
  end;

  lvFilmes.BeginUpdate;

  rectCarregando.Visible := True;
  loading.Enabled        := True;
  
  Thread := TThread.CreateAnonymousThread(procedure
  var
    Json      : String;
    JsonValue : TJSONValue;
    JObj      : TJSONObject;
    Obj       : TJSONValue;
    JsonArray : TJSONArray;
    Filme     : TJSONObject;
    I         : Integer;
    Image     : TImage;
    Stream    : TBytesStream;
  begin
    Json := '';

    Json := GetFilmes(Pagina, Title);

    if lvFilmes.Tag >=0 then
      lvFilmes.Tag := lvFilmes.Tag + 1;

    if Json <> '' then
    begin
      JsonValue   := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(Json), 0);
      JObj        := JsonValue as TJsonObject;
      Obj         := jObj.Get('content').JsonValue;
      TotalPages  := StrToInt(JObj.Get('totalPages').JsonValue.Value);
      JsonArray   := Obj as TJSONArray;

      if JsonArray.Count > 0 then
      begin
        for I := 0 to JsonArray.Count - 1 do
        begin
          Filme := JsonArray.Get(i) as TJsonObject;

          Image := nil;
          Image := TImage.Create(nil);

          Stream := nil;
          Stream := TBytesStream.Create;

          BuscarFromUrlMultiPlatform(Filme.Get('image').JsonValue.Value, Stream);

          Image.Bitmap.LoadFromStream(Stream);

          TThread.Synchronize(nil, procedure
          begin
            AddFilmes(
              lvFilmes, 
              Filme.Get('id').JsonValue.Value,
              Filme.Get('title').JsonValue.Value,
              Filme.Get('count').JsonValue.Value,
              Filme.Get('score').JsonValue.Value,
              Image);
          end);
        end;
          
      end;
    end;
  end);

  Thread.OnTerminate := TThreadEndListarFilmes;
  Thread.Start;
end;

procedure TFrmPrincipal.lvFilmesItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  TRouter4D.Link.
    &To(
    'Filme',
    TProps
      .Create.
      PropString(
        AItem.TagString
      )
      .Key('Filme'));
end;

procedure TFrmPrincipal.lvFilmesPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  if (lvFilmes.Items.Count >=0) and (lvFilmes.Tag >= 0) then
    if lvFilmes.GetItemRect(lvFilmes.Items.Count - 4).Bottom <= lvFilmes.Height then
      if lvFilmes.Tag < TotalPages then
        ListarFilmes(false, lvFilmes.Tag.ToString, editBuscar.Text);
end;

procedure TFrmPrincipal.TThreadEndListarFilmes(Sender: TObject);
begin
  lvFilmes.TagString := '';

  lvFilmes.EndUpdate;

  rectCarregando.Visible := False;
  loading.Enabled        := False;

    if Assigned(TThread(Sender).FatalException) then
    begin
//        TLoading.Hide;
//        TLoading.ToastMessage(
//              FrmProduto,
//              Exception(TThread(Sender).FatalException).Message,
//              TAlignLayout.Top,
//              Utils.cor_erro,
//              $FFFFFFFF,
//              8);
    end;
end;

procedure TFrmPrincipal.AddFilmes(
                              ListView : TListView;
                              IdFilme : String;
                              NomeFilme : String;
                              QtdeAvaliacoes : String;
                              Nota : String;
                              Image : TImage);
var
  Qtde    : Integer;
  Score   : String;
begin
  Qtde := 0;
  Qtde := StrToIntDef(QtdeAvaliacoes, 0);

  with ListView.Items.Add do
  begin
    TagString := IdFilme;

    TListItemText(Objects.FindDrawable('TxtNomeFilme')).Text := NomeFilme;

    if Qtde <= 1 then
      TListItemText(Objects.FindDrawable('TxtAvaliacoes')).Text := Qtde.ToString + ' avalia??o'
    else
      TListItemText(Objects.FindDrawable('TxtAvaliacoes')).Text := Qtde.ToString + ' avalia??es';

    Score := '';
    Score := Nota;
    Score := StringReplace(Score, '.', ',', [rfReplaceAll]);
    Score := StringReplace(FormatFloat('#,##0.0', StrToFloat(Score)), ',', '.', [rfReplaceAll]);

    TListItemText(Objects.FindDrawable('TxtNota')).Text := Score;

    TListItemImage(Objects.FindDrawable('ImgFoto')).Bitmap := Image.Bitmap;
  end;
end;

Procedure TFrmPrincipal.BuscarFromUrlMultiPlatform(Url: string; out Stream : TBytesStream);
var
    Http : THTTPClient;
begin
    try
        try
            Http := THTTPClient.Create;
            Http.Get(Url, Stream);
        except
            raise Exception.Create('Erro no carregamento da imagem!');
        end;

    finally
        if Assigned(Http) then
            Http.Free;
    end;
end;

procedure TFrmPrincipal.CreateRouters;
begin
  TRouter4D.Switch.Router('Filme', TFrmFilme);
end;

procedure TFrmPrincipal.FormCreate(Sender: TObject);
var
  I : Integer;
begin
  inherited;

  CreateRouters;

  lvFilmes.Tag := 0;

  ListarFilmes(True, lvFilmes.Tag.ToString, editBuscar.Text);
end;

function TFrmPrincipal.Render: TFmxObject;
begin
  Result := mainLayout;
end;

procedure TFrmPrincipal.UnRender;
begin

end;

end.

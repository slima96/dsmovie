unit uFrmFilme;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uFrmBase, FMX.Layouts, Router4D, Router4D.Interfaces, FMX.Objects,
  FMX.Controls.Presentation, Router4D.Props, RESTRequest4D, Skia, Skia.FMX,
  System.JSON, System.Net.HttpClient, FMX.Edit;

type
  TFrmFilme = class(TFrmBase, iRouter4DComponent)
    Image1: TImage;
    lblNomeFilme: TLabel;
    lblAvaliacoes: TLabel;
    lblNota: TLabel;
    Label1: TLabel;
    lblSinopse: TLabel;
    rectAvaliar: TRectangle;
    Label2: TLabel;
    rectCarregando: TRectangle;
    loading: TSkAnimatedImage;
    lytContent: TLayout;
    btnVoltar: TCircle;
    iconeVoltar: TSkSvg;
    rectContainerAvaliacao: TRectangle;
    rectContentAvaliacao: TRectangle;
    rectEmail: TRectangle;
    editEmail: TEdit;
    rectNota: TRectangle;
    editNota: TEdit;
    lytBotoes: TLayout;
    rectCancelar: TRectangle;
    Label3: TLabel;
    rectConfirmar: TRectangle;
    Label4: TLabel;
    lblErroEmail: TLabel;
    lytRectEmail: TLayout;
    lytRectNota: TLayout;
    lblErroNota: TLabel;
    procedure btnVoltarClick(Sender: TObject);
    procedure rectContainerAvaliacaoClick(Sender: TObject);
    procedure rectAvaliarClick(Sender: TObject);
    procedure rectConfirmarClick(Sender: TObject);
  private
    IdFilme : String;

    procedure GetFilme(Id: String);
    procedure BuscarFromUrlMultiPlatform(Url: string; out Stream: TBytesStream);
    procedure TThreadEndListarFilmes(Sender: TObject);
    function GerarJSONScore(Email: String; Nota: Integer): String;
    procedure CarregaInformacoesFilme(Filme: Tjsonobject);
    { Private declarations }
  public
    { Public declarations }

    function  Render : TFmxObject;
    procedure UnRender;
    [Subscribe]
    procedure Props(aValue: TProps);
  end;

var
  FrmFilme: TFrmFilme;

implementation

uses
  Utils;

{$R *.fmx}

{ TFrmFilme }

function TFrmFilme.Render: TFmxObject;
begin
  IdFilme := '';
  Result  := mainLayout;
end;

procedure TFrmFilme.UnRender;
begin

end;

procedure TFrmFilme.Props(aValue: TProps);
begin
  if (aValue.PropString <> '') and (aValue.Key = 'Filme') then
  begin
    IdFilme := aValue.PropString;
    GetFilme(aValue.PropString);
  end;
  aValue.Free;
end;

procedure TFrmFilme.rectAvaliarClick(Sender: TObject);
begin
  rectContainerAvaliacao.Visible := True;
end;

Function TFrmFilme.GerarJSONScore(Email : String; Nota : Integer) : String;
var
  jsonObject : TJSONObject;
begin
  jsonObject := TJSONObject.create;

  jsonObject.AddPair('movieId', TJSONNumber.Create(StrToInt(IdFilme)));
  jsonObject.AddPair('email', TJSONString.Create(Email));
  jsonObject.AddPair('score', TJSONNumber.Create(Nota));

  Result := jsonObject.ToJSON;
end;

procedure TFrmFilme.rectConfirmarClick(Sender: TObject);
var
  Thread : TThread;
begin
  if editEmail.Text = '' then
  begin
    lytRectEmail.Height   := 60;
    lblErroEmail.Visible  := true;
    exit;
  end
  else
  begin
    lytRectEmail.Height  := 35;
    lblErroEmail.Visible := False;
  end;

  if editNota.Text = '' then
  begin
    lytRectNota.Height   := 60;
    lblErroNota.Visible  := true;
    exit;
  end
  else
  begin
    lytRectNota.Height  := 35;
    lblErroNota.Visible := False;
  end;

  rectCarregando.Visible          := True;
  loading.Enabled                 := True;
  rectContainerAvaliacao.Visible  := False;

  Thread := TThread.CreateAnonymousThread(procedure
  var
    Json      : String;
    JsonValue : TJSONValue;
    Filme     : TJSONObject;
    Image     : TImage;
    Stream    : TBytesStream;
    LResponse : IResponse;
  begin
    LResponse := TRequest.New.BaseURL(Utils.URL_BASE)
      .Resource('scores')
      .ContentType('application/json')
      .AddBody(GerarJSONScore(editEmail.Text, StrToInt(editNota.Text)))
      .Put;

    Json := '';

    if LResponse.StatusCode in [200, 201, 203] then
      Json := LResponse.Content;

    if Json <> '' then
    begin
      JsonValue   := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(Json), 0);
      Filme       := JsonValue as TJsonObject;

      Image := nil;
      Image := TImage.Create(nil);

      Stream := nil;
      Stream := TBytesStream.Create;

      BuscarFromUrlMultiPlatform(Filme.Get('image').JsonValue.Value, Stream);

      Image.Bitmap.LoadFromStream(Stream);

      TThread.Synchronize(nil, procedure
      begin
        CarregaInformacoesFilme(Filme);

        Image1.Bitmap       := Image.Bitmap;

        editEmail.Text := '';
        editNota.Text  := '';

      end);
    end;
  end);

  Thread.OnTerminate := TThreadEndListarFilmes;
  Thread.Start;

end;

procedure TFrmFilme.CarregaInformacoesFilme(Filme : TJSONObject);
var
  Qtde  : Integer;
  Score : String;
begin
  lblNomeFilme.Text   := Filme.Get('title').JsonValue.Value;

  Qtde := 0;
  Qtde := StrToIntDef(Filme.Get('count').JsonValue.Value, 0);

  if Qtde <= 1 then
    lblAvaliacoes.Text := Qtde.ToString + ' avaliação'
  else
    lblAvaliacoes.Text := Qtde.ToString + ' avaliações';

  Score := '';
  Score := Filme.Get('score').JsonValue.Value;
  Score := StringReplace(Score, '.', ',', [rfReplaceAll]);
  Score := StringReplace(FormatFloat('#,##0.0', StrToFloat(Score)), ',', '.', [rfReplaceAll]);

  lblNota.Text := Score;

  if Filme.Get('synopsis').JsonValue.Value <> 'null' then
    lblSinopse.Text := Filme.Get('synopsis').JsonValue.Value
  else
    lblSinopse.Text := '';
end;

procedure TFrmFilme.rectContainerAvaliacaoClick(Sender: TObject);
begin
  rectContainerAvaliacao.Visible := False;
end;

procedure TFrmFilme.GetFilme(Id : String);
var
  Thread    : TThread;
begin

  rectCarregando.Visible := True;
  loading.Enabled        := True;

  Thread := TThread.CreateAnonymousThread(procedure
  var
    Json      : String;
    JsonValue : TJSONValue;
    Filme     : TJSONObject;
    Image     : TImage;
    Stream    : TBytesStream;
    LResponse : IResponse;
  begin
    LResponse := TRequest.New.BaseURL(Utils.URL_BASE)
      .Resource('movies/' + Id)
      .Accept('application/json')
      .Get;

    Json := '';

    if LResponse.StatusCode in [200, 201, 203] then
      Json := LResponse.Content;

    if Json <> '' then
    begin
      JsonValue   := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(Json), 0);
      Filme       := JsonValue as TJsonObject;

      Image := nil;
      Image := TImage.Create(nil);

      Stream := nil;
      Stream := TBytesStream.Create;

      BuscarFromUrlMultiPlatform(Filme.Get('image').JsonValue.Value, Stream);

      Image.Bitmap.LoadFromStream(Stream);

      TThread.Synchronize(nil, procedure
      begin
        CarregaInformacoesFilme(Filme);

        Image1.Bitmap       := Image.Bitmap;

        lytContent.Visible := True;
      end);
    end;
  end);

  Thread.OnTerminate := TThreadEndListarFilmes;
  Thread.Start;
end;

procedure TFrmFilme.TThreadEndListarFilmes(Sender: TObject);
begin
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

procedure TFrmFilme.btnVoltarClick(Sender: TObject);
begin
  TRouter4D.Link.&To('Principal');
  lytContent.Visible := False;
end;

Procedure TFrmFilme.BuscarFromUrlMultiPlatform(Url: string; out Stream : TBytesStream);
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

end.

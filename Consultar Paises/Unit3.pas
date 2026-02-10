unit Unit3;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  System.Net.HttpClientComponent, System.Net.HttpClient, System.JSON,
  System.Net.URLClient, System.NetEncoding;

type
  TForm3 = class(TForm)
    edtPais: TEdit;
    btnConsultar: TButton;
    lblNomeOficial: TLabel;
    lblCapital: TLabel;
    lblRegiao: TLabel;
    lblPopulacao: TLabel;
    lblMoeda: TLabel;
    NetHTTPClient1: TNetHTTPClient;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure btnConsultarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
var
  Form3: TForm3;

implementation

{$R *.dfm}

procedure TForm3.btnConsultarClick(Sender: TObject);
var
  LResponse: IHTTPResponse;
  LURL: string;
  LJSONValue, LCountry, LCurrencies, LCurrencyData: TJSONValue;
  LJSONArray: TJSONArray;
begin
  // 1. Validação do campo vazio
  if Trim(edtPais.Text) = '' then
  begin
    ShowMessage('Por favor, digite o nome de um país.');
    Exit;
  end;

  // Limpar campos para nova consulta
  lblNomeOficial.Caption := '...';
  lblCapital.Caption     := '...';
  lblRegiao.Caption      := '...';
  lblPopulacao.Caption   := '...';
  lblMoeda.Caption       := '...';

  // 2. Montar a URL com tratamento de caracteres especiais (acentos/espaços)
  LURL := 'https://restcountries.com/v3.1/name/' + TNetEncoding.URL.Encode(edtPais.Text);

  try
    // 3. Requisição HTTP GET
    LResponse := NetHTTPClient1.Get(LURL);

    if LResponse.StatusCode = 200 then
    begin
      // 4. Parse do JSON
      LJSONValue := TJSONObject.ParseJSONValue(LResponse.ContentAsString);
      try
        if (LJSONValue is TJSONArray) then
        begin
          LJSONArray := LJSONValue as TJSONArray;
          LCountry   := LJSONArray.Items[0]; // Pega o primeiro resultado

          // Nome Oficial
          lblNomeOficial.Caption := LCountry.GetValue<TJSONObject>('name').GetValue<string>('official');

          // Capital (é um array no JSON)
          if (LCountry.GetValue<TJSONArray>('capital') <> nil) then
            lblCapital.Caption := LCountry.GetValue<TJSONArray>('capital').Items[0].Value;

          // Região
          lblRegiao.Caption := LCountry.GetValue<string>('region');

          // População (Formatado com separador de milhar)
          lblPopulacao.Caption := FormatFloat('#,##0', LCountry.GetValue<Double>('population'));

          // Moeda (Acessando a primeira chave dentro de "currencies")
          LCurrencies := LCountry.GetValue<TJSONObject>('currencies');
          if (LCurrencies is TJSONObject) and (TJSONObject(LCurrencies).Count > 0) then
          begin
             LCurrencyData := TJSONObject(LCurrencies).Pairs[0].JsonValue;
             lblMoeda.Caption := LCurrencyData.GetValue<string>('name');
          end;
        end;
      finally
        LJSONValue.Free;
      end;
    end
    else if LResponse.StatusCode = 404 then
      ShowMessage('País não encontrado!')
    else
      ShowMessage('Erro: ' + LResponse.StatusText);

  except
    on E: Exception do
      ShowMessage('Falha na conexão: ' + E.Message);
  end;
end;

end.

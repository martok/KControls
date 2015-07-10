unit KMemoRTF;

interface

uses
  Classes, Contnrs, Graphics, Controls,
  KControls, KFunctions, KGraphics, KMemo;

type
  TKMemoRTFGroup = (rgNone, rgUnknown, rgColorTable, rgFontTable, rgHeader, rgInfo, rgPicture, rgShape, rgShapeInst, rgShapeResult, rgShapePict, rgStyleSheet, rgText);

  TKMemoRTFColor = class(TObject)
  private
    FColorRec: TKColorRec;
  public
    constructor Create;
    property ColorRec: TKColorRec read FColorRec write FColorRec;
    property Red: Byte read FColorRec.R write FColorRec.R;
    property Green: Byte read FColorRec.G write FColorRec.G;
    property Blue: Byte read FColorRec.B write FColorRec.B;
  end;

  TKMemoRTFColorTable = class(TObjectList)
  private
    function GetItem(Index: Integer): TKMemoRTFColor;
    procedure SetItem(Index: Integer; const Value: TKMemoRTFColor);
  public
    procedure AddColor(const AColor: TKColorRec);
    function GetColor(AIndex: Integer): TColor; virtual;
    property Items[Index: Integer]: TKMemoRTFColor read GetItem write SetItem; default;
  end;

  TKMemoRTFFont = class(TObject)
  private
    FFont: TFont;
    FFontIndex: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    property Font: TFont read FFont;
    property FontIndex: Integer read FFontIndex write FFontIndex;
  end;

  TKMemoRTFFontTable = class(TObjectList)
  private
    function GetItem(Index: Integer): TKMemoRTFFont;
    procedure SetItem(Index: Integer; const Value: TKMemoRTFFont);
  public
    function GetFont(AFontIndex: Integer): TFont;
    property Items[Index: Integer]: TKMemoRTFFont read GetItem write SetItem; default;
  end;

  TKMemoRTFShapeContentType = (sctUnknown, sctContainer, sctImage, sctRectangle, sctText);

  TKMemoRTFShape = class(TObject)
  private
    FContentPosition: TKRect;
    FContentType: TKMemoRTFShapeContentType;
    FCtrlName: AnsiString;
    FCtrlValue: AnsiString;
    FStyle: TKMemoBlockStyle;
    FWrap: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    property ContentPosition: TKRect read FContentPosition;
    property ContentType: TKMemoRTFShapeContentType read FContentType write FContentType;
    property CtrlName: AnsiString read FCtrlName write FCtrlName;
    property CtrlValue: AnsiString read FCtrlValue write FCtrlValue;
    property Style: TKMemoBlockStyle read FStyle;
    property Wrap: Integer read FWrap write FWrap;
  end;

  TKMemoRTFReader = class(TObject)
  private
    function GetActiveFont: TKMemoRTFFont;
    function GetActiveColor: TKMemoRTFColor;
    function GetActiveImage: TKMemoImageBlock;
    function GetActiveShape: TKMemoRTFShape;
    function GetActiveContainer: TKMemoContainer;
    function GetActiveTable: TKMemoTable;
  protected
    FActiveColor: TKMemoRTFColor;
    FActiveFont: TKMemoRTFFont;
    FActiveImage: TKMemoImageBlock;
    FActiveShape: TKMemoRTFShape;
    FActiveTable: TKMemoTable;
    FActiveText: TKMemoTextBlock;
    FBackgroundImage: Boolean;
    FBlocks: TKMemoBlocks;
    FColorTable: TKMemoRTFColorTable;
    FActiveContainer: TKMemoContainer;
    FDefCodePage: Integer;
    FDefFontIndex: Integer;
    FFontTable: TKMemoRTFFontTable;
    FHeaderRead: Boolean;
    FImageClass: TGraphicClass;
    FGraphicClass: TGraphicClass;
    FMemo: TKCustomMemo;
    FStream: TMemoryStream;
    FTableBorder: TAlign;
    FTableCell: TKMemoTableCell;
    FTableCol: Integer;
    FTableColCount: Integer;
    FTableRow: TKMemoTableRow;
    FTableLastRow: Boolean;
    FTextStyle: TKMemoTextStyle;
    procedure AddText(const APart: TKString; ATextStyle: TKMemoTextStyle); virtual;
    procedure ApplyFont(ATextStyle: TKMemoTextStyle; AFontIndex: Integer); virtual;
    procedure ApplyHighlight(ATextStyle: TKMemoTextStyle; AHighlightCode: Integer); virtual;
    function DirectBool(const AValue: AnsiString): Boolean; virtual;
    function DirectColor(const AValue: AnsiString): TColor; virtual;
    function DirectEMU(const AValue: AnsiString): Integer; virtual;
    function EMUToPoints(AValue: Integer): Integer;
    procedure FlushColor; virtual;
    procedure FlushContainer; virtual;
    procedure FlushFont; virtual;
    procedure FlushImage; virtual;
    procedure FlushShape; virtual;
    procedure FlushTable; virtual;
    procedure FlushText; virtual;
    function HighlightCodeToColor(AValue: Integer): TColor; virtual;
    function ReadNext(out ACtrl, AText: AnsiString; out AParam: Int64): Boolean; virtual;
    procedure ReadColorGroup(const ACtrl, AText: AnsiString; AParam: Integer); virtual;
    procedure ReadFontGroup(const ACtrl, AText: AnsiString; AParam: Integer); virtual;
    function ReadHeaderGroup(const ACtrl, AText: AnsiString; AParam: Integer; var Group: TKMemoRTFGroup): Boolean; virtual;
    procedure ReadGroup(GroupIndex: Integer; Group: TKMemoRTFGroup; ATextStyle: TKMemoTextStyle; AParaStyle: TKMemoParaStyle); virtual;
    procedure ReadPictureGroup(const ACtrl, AText: AnsiString; AParam: Integer); virtual;
    function ReadShapeGroup(const ACtrl, AText: AnsiString; AParam: Integer): Boolean; virtual;
    function ReadParaFormatting(const ACtrl: AnsiString; AParam: Integer; AParaStyle: TKMemoParaStyle): Boolean; virtual;
    function ReadTableFormatting(const ACtrl: AnsiString; AParam: Integer): Boolean; virtual;
    function ReadTextFormatting(const ACtrl: AnsiString; AParam: Integer; ATextStyle: TKMemoTextStyle): Boolean; virtual;
    function TwipsToPoints(AValue: Integer): Integer;
    property ActiveColor: TKMemoRTFColor read GetActiveColor;
    property ActiveContainer: TKMemoContainer read GetActiveContainer;
    property ActiveFont: TKMemoRTFFont read GetActiveFont;
    property ActiveImage: TKMemoImageBlock read GetActiveImage;
    property ActiveShape: TKMemoRTFShape read GetActiveShape;
    property ActiveTable: TKMemoTable read GetActiveTable;
  public
    constructor Create(AMemo: TKCustomMemo); virtual;
    destructor Destroy; override;
    procedure Load(const AFileName: TKString); virtual;
  end;

  TKMemoRTFWriter = class(TObject)
  end;

implementation

uses
  Math, SysUtils, KHexEditor
{$IFnDEF FPC}
  , JPeg
{$ENDIF}
  ;

{ TKMemoRTFColor }

constructor TKMemoRTFColor.Create;
begin
  FColorRec.Value := 0;
end;

{ TKMemoRTFColorTable }

procedure TKMemoRTFColorTable.AddColor(const AColor: TKColorRec);
var
  Value: TKMemoRTFColor;
begin
  Value := TKMemoRTFColor.Create;
  Value.ColorRec := AColor;
  Add(Value);
end;

function TKMemoRTFColorTable.getColor(AIndex: Integer): TColor;
begin
  if (AIndex >= 0) and (AIndex < Count) then
    Result := ColorRecToColor(Items[AIndex].ColorRec)
  else
    Result := clNone;
end;

function TKMemoRTFColorTable.GetItem(Index: Integer): TKMemoRTFColor;
begin
  Result := TKMemoRTFColor(inherited GetItem(Index));
end;

procedure TKMemoRTFColorTable.SetItem(Index: Integer; const Value: TKMemoRTFColor);
begin
  inherited SetItem(Index, Value);
end;

{ TKMemoRTFFont }

constructor TKMemoRTFFont.Create;
begin
  FFont := TFont.Create;
end;

destructor TKMemoRTFFont.Destroy;
begin
  FFont.Free;
  inherited;
end;

{ TKMemoRTFFontTable }

function TKMemoRTFFontTable.GetFont(AFontIndex: Integer): TFont;
var
  I: Integer;
  Item: TKMemoRTFFont;
begin
  Result := nil;
  for I := 0 to Count - 1 do
  begin
    Item := Items[I];
    if Item.FontIndex = AFontIndex then
    begin
      Result := Item.Font;
      Exit;
    end;
  end;
end;

function TKMemoRTFFontTable.GetItem(Index: Integer): TKMemoRTFFont;
begin
  Result := TKMemoRTFFont(inherited GetItem(Index));
end;

procedure TKMemoRTFFontTable.SetItem(Index: Integer;
  const Value: TKMemoRTFFont);
begin
  inherited SetItem(Index, Value);
end;

{ TKMemoRTFShape }

constructor TKMemoRTFShape.Create;
begin
  FContentPosition := TKRect.Create;
  FContentType := sctUnknown;
  FStyle := TKMemoBlockStyle.Create;
  FStyle.Brush.Color := clWhite;
  FStyle.BorderWidth := 1;
  FStyle.ContentPadding.AssignFromValues(2, 2, 2, 2);
  FWrap := 0;
end;

destructor TKMemoRTFShape.Destroy;
begin
  FContentPosition.Free;
  FStyle.Free;
  inherited;
end;

{ TKMemoRTFReader }

constructor TKMemoRTFReader.Create(AMemo: TKCustomMemo);
begin
  FBlocks := AMemo.Blocks;
  FColorTable := TKMemoRTFColorTable.Create;
  FFontTable := TKMemoRTFFontTable.Create;
  FMemo := AMemo;
  FStream := TMemoryStream.Create;
  FTextStyle := TKMemoTextStyle.Create;
end;

destructor TKMemoRTFReader.Destroy;
begin
  FColorTable.Free;
  FFontTable.Free;
  FStream.Free;
  FTextStyle.Free;
  inherited;
end;

function TKMemoRTFReader.DirectBool(const AValue: AnsiString): Boolean;
begin
  Result := Boolean(StrToIntDef(string(AValue), 0));
end;

function TKMemoRTFReader.DirectColor(const AValue: AnsiString): TColor;
begin
  Result := ColorRecToColor(MakeColorRec(StrToIntDef(string(AValue), 0)));
end;

function TKMemoRTFReader.DirectEMU(const AValue: AnsiString): Integer;
begin
  Result := EMUToPoints(StrToIntDef(string(AValue), 0));
end;

function TKMemoRTFReader.EMUToPoints(AValue: Integer): Integer;
begin
  Result := DivUp(AValue, 12700);
end;

procedure TKMemoRTFReader.AddText(const APart: TKString; ATextStyle: TKMemoTextStyle);
begin
  FTextStyle.Assign(ATextStyle);
  if FTextStyle.StyleChanged then
  begin
    FlushText;
    FTextStyle.StyleChanged := False;
  end;
  if FActiveText = nil then
  begin
    FActiveText := TKMemoTextBlock.Create(nil);
    FActiveText.TextStyle.Assign(FTextStyle);
  end;
  FActiveText.InsertString(APart);
end;

procedure TKMemoRTFReader.ApplyFont(ATextStyle: TKMemoTextStyle; AFontIndex: Integer);
var
  Font: TFont;
begin
  Font := FFontTable.GetFont(AFontIndex);
  if Font <> nil then
  begin
    ATextStyle.Font.Name := Font.Name;
    ATextStyle.Font.Charset := Font.Charset;
    ATextStyle.Font.Pitch := Font.Pitch;
  end;
end;

procedure TKMemoRTFReader.ApplyHighlight(ATextStyle: TKMemoTextStyle; AHighlightCode: Integer);
var
  Color: TColor;
begin
  Color := HighlightCodeToColor(AHighlightCode);
  if Color <> clNone then
    ATextStyle.Brush.Color := Color
  else
    ATextStyle.Brush.Style := bsClear;
end;

procedure TKMemoRTFReader.FlushColor;
begin
  if FActiveColor <> nil then
  begin
    FColorTable.Add(FActiveColor);
    FActiveColor := nil;
  end;
end;

procedure TKMemoRTFReader.FlushContainer;
begin
  if FActiveContainer <> nil then
  begin
    FBlocks := FActiveContainer.Parent;
    FBlocks.AddAt(FActiveContainer);
    FActiveContainer := nil;
  end;
end;

procedure TKMemoRTFReader.FlushFont;
begin
  if FActiveFont <> nil then
  begin
    FFontTable.Add(FActiveFont);
    FActiveFont := nil;
  end;
end;

procedure TKMemoRTFReader.FlushImage;
begin
  if FActiveImage <> nil then
  begin
    FBlocks.AddAt(FActiveImage);
    FActiveImage := nil;
  end;
end;

procedure TKMemoRTFReader.FlushShape;
begin
  if FActiveShape <> nil then
  begin
    case FActiveShape.ContentType of
      sctImage:
      begin
        // image was inside shape
        if FActiveImage <> nil then
        begin
          ActiveImage.Position := mbpRelative;
          ActiveImage.LeftOffset := FActiveShape.ContentPosition.Left;
          ActiveImage.TopOffset := FActiveShape.ContentPosition.Top;
          ActiveImage.ImageStyle.Assign(FActiveShape.Style);
          FlushImage;
        end;
      end;
      sctRectangle:
      begin
        // currently only document background supported
        if FBackgroundImage then
        begin
          if FActiveImage <> nil then
          begin
            FMemo.BackgroundImage.Assign(ActiveImage.Image);
            FreeAndNil(FActiveImage);
          end else
            FMemo.Colors.BkGnd := FActiveShape.Style.Brush.Color;
          FBackgroundImage := False;
        end;
      end;
      sctContainer:
      begin
        if FActiveContainer <> nil then
        begin
          // container was inside shape
          ActiveContainer.Position := mbpRelative;
          ActiveContainer.FixedWidth := True;
          ActiveContainer.LeftOffset := FActiveShape.ContentPosition.Left;
          ActiveContainer.TopOffset := FActiveShape.ContentPosition.Top;
          ActiveContainer.RequiredWidth := FActiveShape.ContentPosition.Right - FActiveShape.ContentPosition.Left;
          ActiveContainer.RequiredHeight := FActiveShape.ContentPosition.Bottom - FActiveShape.ContentPosition.Top;
          ActiveContainer.BlockStyle.Assign(FActiveShape.Style);
          FlushContainer;
        end;
      end;
      sctText:
      begin
        // unformatted text was inside shape
        FlushText;
      end;
    end;
    FreeAndNil(FActiveShape);
  end;
end;

procedure TKMemoRTFReader.FlushTable;
begin
  if FActiveTable <> nil then
  begin
    //FTable.Position := mbpRelative;
    FActiveTable.FixupBorders;
    FBlocks := FActiveTable.Parent;
    FBlocks.AddAt(FActiveTable);
    FBlocks.AddParagraph;
    FActiveTable := nil;
  end;
end;

procedure TKMemoRTFReader.FlushText;
begin
  if FActiveText <> nil then
  begin
    if FBlocks <> nil then
      FBlocks.AddAt(FActiveText);
    FActiveText := nil;
  end;
end;

function TKMemoRTFReader.GetActiveColor: TKMemoRTFColor;
begin
  if FActiveColor = nil then
    FActiveColor := TKMemoRTFColor.Create;
  Result := FActiveColor;
end;

function TKMemoRTFReader.GetActiveContainer: TKMemoContainer;
begin
  if FActiveContainer = nil then
    FActiveContainer := TKMemoContainer.Create(FBlocks);
  Result := FActiveContainer;
end;

function TKMemoRTFReader.GetActiveFont: TKMemoRTFFont;
begin
  if FActiveFont = nil then
    FActiveFont := TKMemoRTFFont.Create;
  Result := FActiveFont;
end;

function TKMemoRTFReader.GetActiveImage: TKMemoImageBlock;
begin
  if FActiveImage = nil then
    FActiveImage := TKMemoImageBlock.Create(nil);
  Result := FActiveImage;
end;

function TKMemoRTFReader.GetActiveShape: TKMemoRTFShape;
begin
  if FActiveShape = nil then
    FActiveShape := TKMemoRTFShape.Create;
  Result := FActiveShape;
end;

function TKMemoRTFReader.GetActiveTable: TKMemoTable;
begin
  if FActiveTable = nil then
    FActiveTable := TKMemoTable.Create(FBlocks);
  Result := FActiveTable;
end;

function TKMemoRTFReader.HighlightCodeToColor(AValue: Integer): TColor;
begin
  case AValue of
    1: Result := clBlack;
    2: Result := clBlue;
    3: Result := clAqua; // cyan
    4: Result := clLime; // green
    5: Result := clFuchsia; // magenta
    6: Result := clRed;
    7: Result := clYellow;
    9: Result := clNavy;
    10: Result := clTeal; // dark cyan
    11: Result := clGreen; // dark green
    12: Result := clPurple; // dark magenta
    13: Result := clMaroon; // dark red
    14: Result := clOlive; // dark yellow
    15: Result := clGray; // dark gray
    16: Result := clSilver; // light gray
  else
    Result := clNone;
  end;
end;

procedure TKMemoRTFReader.Load(const AFileName: TKString);
begin
  if FileExists(AFileName) then
  try
    FStream.LoadFromFile(AFileName);
    FMemo.TextStyle.Defaults;
    FMemo.ParaStyle.Defaults;
    FMemo.Colors.BkGnd := cBkGndDef;
    FMemo.BackgroundImage.Graphic := nil;
    FActiveColor := nil;
    FActiveContainer := nil;
    FActiveFont := nil;
    FActiveImage := nil;
    FActiveShape := nil;
    FActiveTable := nil;
    FActiveText := nil;
    FBackgroundImage := False;
    FColorTable.Clear;
    FDefCodePage := 0;
    FDefFontIndex := 0;
    FHeaderRead := False;
    FImageClass := nil;
    FTableBorder := alNone;
    FTableCell := nil;
    FTableCol := -1;
    FTableColCount := 0;
    FTableRow := nil;
    FBlocks.LockUpdate;
    try
      FBlocks.Clear;
      ReadGroup(0, rgNone, FMemo.TextStyle, FMemo.ParaStyle);
    finally
      FlushColor;
      FlushFont;
      FlushText;
      FlushShape;
      FlushImage;
      FBlocks.UnlockUpdate;
    end;
  except
  end;
end;

function TKMemoRTFReader.ReadNext(out ACtrl, AText: AnsiString; out AParam: Int64): Boolean;

  procedure ReadText(var AText: AnsiString; AChar: AnsiChar);
  begin
    repeat
      if (AChar <> cCR) and (AChar <> cLF) then
        AText := AText + AChar;
      Result := FStream.Read(AChar, 1) > 0;
    until CharInSetEx(AChar, ['{', '}', '\']) or not Result;
    FStream.Seek(-1, soFromCurrent);
  end;

var
  C: AnsiChar;
  ParamStr: AnsiString;
  Code: Integer;
begin
  AParam := MaxInt;
  ACtrl := '';
  AText := '';
  Result := FStream.Read(C, 1) > 0;
  if C = '\' then
  begin
    FStream.Read(C, 1);
    if CharInSetEx(C, cLetters) then
    begin
      // control word
      repeat
        ACtrl := ACtrl + C;
        Result := FStream.Read(C, 1) > 0;
      until not (Result and CharInSetEx(C, cLetters));
      if (C = '-') or CharInSetEx(C, cNumbers) then
      begin
        // control word parameter
        ParamStr := '';
        repeat
          ParamStr := ParamStr + C;
          Result := FStream.Read(C, 1) > 0;
        until not (Result and CharInSetEx(C, cNumbers));
        AParam := StrToIntDef(TKString(ParamStr), 0);
        if C <> ' ' then
          FStream.Seek(-1, soFromCurrent);
      end
      else if C <> ' ' then
        FStream.Seek(-1, soFromCurrent);
    end else
    begin
      ACtrl := C; //control symbol
      if C = '''' then
      begin
        //hexadecimal value - special symbol
        SetLength(ParamStr, 2);
        Result := FStream.Read(ParamStr[1], 2) = 2;
        if Result then
          AParam := HexStrToInt(string(ParamStr), Length(ParamStr), False, Code);
      end;
    end;
    if FStream.Read(C, 1) > 0 then
    begin
      if CharInSetEx(C, ['{', '}', '\']) then
        FStream.Seek(-1, soFromCurrent)
      else
        ReadText(AText, C);
    end;
  end
  else if CharInSetEx(C, ['{', '}', ';']) then
    ACtrl := C // group
  else
    ReadText(AText, C);
end;

procedure TKMemoRTFReader.ReadColorGroup(const ACtrl, AText: AnsiString; AParam: Integer);
begin
  if ACtrl = 'red' then
    ActiveColor.Red := Byte(AParam)
  else if ACtrl = 'green' then
    ActiveColor.Green := Byte(AParam)
  else if ACtrl = 'blue' then
    ActiveColor.Blue := Byte(AParam);
  if AText = ';' then
    FlushColor;
end;

procedure TKMemoRTFReader.ReadFontGroup(const ACtrl, AText: AnsiString; AParam: Integer);
var
  I: Integer;
  S: string;
begin
  if ACtrl = 'f' then
    ActiveFont.FFontIndex := AParam
  else if ACtrl = 'fcharset' then
    ActiveFont.Font.Charset := AParam
  else if ACtrl = 'fprq' then
  begin
    case AParam of
      1: ActiveFont.Font.Pitch := fpFixed;
      2: ActiveFont.Font.Pitch := fpVariable;
    else
      ActiveFont.Font.Pitch := fpDefault;
    end;
    ActiveFont.Font.Pitch := TFontPitch(AParam)
  end
  else if (ACtrl = '') and (AText <> '') then
  begin
    S := string(AText);
    I := Pos(';', S);
    if I > 0 then
      Delete(S, I, 1);
    ActiveFont.Font.Name := S;
    FlushFont;
  end
end;

procedure TKMemoRTFReader.ReadGroup(GroupIndex: Integer; Group: TKMemoRTFGroup; ATextStyle: TKMemoTextStyle; AParaStyle: TKMemoParaStyle);
var
  Ctrl: AnsiString;
  Text: AnsiString;
  Param: Int64;
  LocalTextStyle: TKMemoTextStyle;
  LocalParaStyle: TKMemoParaStyle;
  PA: TKMemoParagraph;
  IsPicture, IsShapeInst: Boolean;
begin
  IsPicture := False;
  IsShapeInst := False;
  LocalParaStyle := TKMemoParaStyle.Create;
  LocalTextStyle := TKMemoTextStyle.Create;
  try
    LocalParaStyle.Assign(AParaStyle);
    LocalTextStyle.Assign(ATextStyle);
    Ctrl := '';
    while (FStream.Position < FStream.Size) and (Ctrl <> '}') do
    begin
      ReadNext(Ctrl, Text, Param);
      if (Ctrl <> '') or (Text <> '') then
      begin
       if Ctrl = '{' then
          ReadGroup(GroupIndex + 1, Group, LocalTextStyle, LocalParaStyle)
        else if Ctrl = '*' then
        begin
          if Group <> rgShape then
            Group := rgUnknown;
        end
        else if Ctrl <> '}' then
        begin
          case Group of
            rgColorTable: ReadColorGroup(Ctrl, Text, Param);
            rgFontTable: ReadFontGroup(Ctrl, Text, Param);
            rgInfo:;
            rgPicture: ReadPictureGroup(Ctrl, Text, Param);
            rgShape:
            begin
              if Ctrl = 'shpinst' then
              begin
                IsShapeInst := True;
                Group := rgShapeInst;
              end;
            end;
            rgShapeInst: if not ReadShapeGroup(Ctrl, Text, Param) then
            begin
              if Ctrl = 'pict' then
              begin
                Group := rgPicture // picture in this shape
              end
              else if Ctrl = 'shptxt' then
              begin
                FlushText;
                ActiveShape.ContentType := sctContainer;
                FBlocks := ActiveContainer.Blocks;
                Group := rgText // text in this shape
              end;
            end;
            rgShapePict:
            begin
              if Ctrl = 'pict' then
              begin
                Group := rgPicture;
                IsPicture := True;
              end;
            end;
            rgStyleSheet:;
            rgUnknown:
            begin
              if Ctrl = 'shppict' then
              begin
                FlushShape;
                Group := rgShapePict; // picture inside text
              end
              else if Ctrl = 'background' then
              begin
                FBackgroundImage := True;
                Group := rgNone;
              end;
            end;
          else
            if not FHeaderRead then
            begin
              if Ctrl = 'rtf' then
                FHeaderRead := True;
            end else
            begin
              if Ctrl <> '' then
              begin
                // header control words (unfortunately header has not its own group)
                if ReadHeaderGroup(Ctrl, Text, Param, Group) then
                begin
                  Text := '';
                end
                // body control words
                else if Ctrl = 'info' then
                begin
                  Group := rgInfo;
                end
                else if Ctrl = 'shp' then
                begin
                  Group := rgShape;
                end
                else if Ctrl = 'nonshppict' then
                begin
                  Group := rgUnknown;
                end
                else if Ctrl = 'par' then
                begin
                  FlushText;
                  PA := FBlocks.AddParagraph;
                  PA.TextStyle.Assign(LocalTextStyle);
                  PA.ParaStyle.Assign(LocalParaStyle);
                end
                // supported table commands
                else if ReadTableFormatting(Ctrl, Param) then
                begin
                end
                // supported text formatting
                else if ReadTextFormatting(Ctrl, Param, LocalTextStyle) then
                begin
                end
                // supported paragraph formatting
                else if ReadParaFormatting(Ctrl, Param, LocalParaStyle) then
                begin
                end
                // supported special characters
                else if (Ctrl = '''') then
                begin
                  AddText(AnsiStringToString(AnsiChar(Param), FDefCodePage), LocalTextStyle);
                end
                else if Ctrl = 'tab' then
                begin
                  AddText(#9, LocalTextStyle);
                end
                else if Ctrl = '~' then
                begin
                  AddText(' ', LocalTextStyle); // nonbreaking spaces not supported yet
                end
                else if (Ctrl = '\') or (Ctrl = '{') or (Ctrl = '}') then
                begin
                  AddText(TKString(Ctrl), LocalTextStyle)
                end;
              end;
              if Text <> '' then
              begin
                AddText(TKString(Text), LocalTextStyle);
              end
            end;
          end;
        end;
      end;
    end;
    if IsPicture then
      FlushImage;
    if IsShapeInst then
      FlushShape;
  finally
    LocalParaStyle.Free;
    LocalTextStyle.Free;
  end;
end;

function TKMemoRTFReader.ReadHeaderGroup(const ACtrl, AText: AnsiString; AParam: Integer; var Group: TKMemoRTFGroup): Boolean;
begin
  Result := True;
  if ACtrl = 'ansicpg' then
  begin
    FDefCodePage := AParam;
  end
  else if ACtrl = 'deff' then
  begin
    FDefFontIndex := AParam;
  end
  else if ACtrl = 'fonttbl' then
  begin
    Group := rgFontTable;
  end
  else if ACtrl = 'colortbl' then
  begin
    Group := rgColorTable;
  end
  else if ACtrl = 'stylesheet' then
  begin
    Group := rgStyleSheet;
  end else
    Result := False;
end;

function TKMemoRTFReader.ReadParaFormatting(const ACtrl: AnsiString;
  AParam: Integer; AParaStyle: TKMemoParaStyle): Boolean;
begin
  Result := True;
  if ACtrl = 'pard' then
  begin
    AParaStyle.Assign(FMemo.ParaStyle);
  end
  else if ACtrl = 'fi' then
  begin
    AParaStyle.FirstIndent := TwipsToPoints(AParam);
  end
  else if ACtrl = 'li' then
  begin
    AParaStyle.LeftPadding := TwipsToPoints(AParam);
  end
  else if ACtrl = 'ri' then
  begin
    AParaStyle.RightPadding := TwipsToPoints(AParam);
  end
  else if ACtrl = 'sb' then
  begin
    AParaStyle.TopPadding := TwipsToPoints(AParam);
  end
  else if ACtrl = 'sa' then
  begin
    AParaStyle.BottomPadding := TwipsToPoints(AParam);
  end
  else if ACtrl = 'ql' then
  begin
    AParaStyle.HAlign := halLeft;
  end
  else if ACtrl = 'qr' then
  begin
    AParaStyle.HAlign := halRight;
  end
  else if ACtrl = 'qc' then
  begin
    AParaStyle.HAlign := halCenter;
  end
  else if ACtrl = 'qj' then
  begin
    AParaStyle.HAlign := halJustify;
  end
  else if ACtrl = 'cbpat' then
  begin
    AParaStyle.Brush.Color := FColorTable.GetColor(AParam - 1);
  end
  else
    Result := False;
end;

procedure TKMemoRTFReader.ReadPictureGroup(const ACtrl, AText: AnsiString; AParam: Integer);
var
  S: AnsiString;
  MS: TMemoryStream;
  Image: TGraphic;
begin
  if ACtrl = 'pngblip' then
    FImageClass := TKPngImage
{$IFDEF FPC_METAFILE}
  else if ACtrl = 'wmetafile' then
    FImageClass := TMetafile
{$ENDIF}
  else if ACtrl = 'jpegblip' then
    FImageClass := TJpegImage
  else if ACtrl = 'picwgoal' then
    ActiveImage.ScaleWidth := TwipsToPoints(AParam)
  else if ACtrl = 'pichgoal' then
    ActiveImage.ScaleHeight := TwipsToPoints(AParam)
  else if (ACtrl = '') and (AText <> '') then
  begin
    if FImageClass <> nil then
    begin
      S := AText;
      if DigitsToBinStr(S) then
      begin
        S := BinStrToBinary(S);
        try
          MS := TMemoryStream.Create;
          try
            MS.Write(S[1], Length(S));
            MS.Seek(0, soFromBeginning);
            Image := FImageClass.Create;
            try
              Image.LoadFromStream(MS);
              ActiveImage.Image.Graphic := Image;
            finally
              Image.Free;
            end;
          finally
            MS.Free;
          end;
        except
        end;
      end;
      FImageClass := nil;
    end;
  end;
end;

function TKMemoRTFReader.ReadShapeGroup(const ACtrl, AText: AnsiString; AParam: Integer): Boolean;
begin
  Result := True;
  if ACtrl = 'shpleft' then
    ActiveShape.ContentPosition.Left := TwipsToPoints(AParam)
  else if ACtrl = 'shpright' then
    ActiveShape.ContentPosition.Right := TwipsToPoints(AParam)
  else if ACtrl = 'shptop' then
    ActiveShape.ContentPosition.Top := TwipsToPoints(AParam)
  else if ACtrl = 'shpbottom' then
    ActiveShape.ContentPosition.Bottom := TwipsToPoints(AParam)
  else if ACtrl = 'shpwr' then
    ActiveShape.Wrap := AParam
  else if ACtrl = 'sn' then
    ActiveShape.CtrlName := AText
  else if ACtrl = 'sv' then
  begin
    ActiveShape.CtrlValue := AText;
    if ActiveShape.CtrlName = 'fFilled' then
    begin
      if not DirectBool(AText) then
        ActiveShape.Style.Brush.Style := bsClear;
    end
    else if ActiveShape.CtrlName = 'fillColor' then
      ActiveShape.Style.Brush.Color := DirectColor(AText)
    else if ActiveShape.CtrlName = 'fLine' then
    begin
      if not DirectBool(AText) then
        ActiveShape.Style.BorderWidth := 0;
    end
    else if ActiveShape.CtrlName = 'lineColor' then
      ActiveShape.Style.BorderColor := DirectColor(AText)
    else if ActiveShape.CtrlName = 'lineWidth' then
      ActiveShape.Style.BorderWidth := DirectEMU(AText)
    else if ActiveShape.CtrlName = 'shapeType' then
    begin
      // supported shape types
      case StrToIntDef(ActiveShape.CtrlValue, 0) of
        1: ActiveShape.ContentType := sctRectangle;
        75: ActiveShape.ContentType := sctImage;
      end;
    end;
  end
  else
    Result := False;
end;

function TKMemoRTFReader.ReadTableFormatting(const ACtrl: AnsiString;
  AParam: Integer): Boolean;
var
  I, Value: Integer;
begin
  Result := True;
  if FTableColCount = 0 then
  begin
    if ACtrl = 'trowd' then // start of a row
    begin
      FlushText;
      if FActiveTable = nil then
      begin
        ActiveTable.RowCount := 1;
        ActiveTable.ColCount := 1;
        FTableColCount := 1;
        FTableRow := ActiveTable.Rows[ActiveTable.RowCount - 1];
        FBlocks := FTableRow.Cells[FTableColCount - 1].Blocks; // starting new cell
      end;
    end else
      Result := False;
  end
  else if FTableRow <> nil then
  begin
    if ACtrl = 'cell' then // end of a cell
    begin
      FlushText;
      Inc(FTableColCount);
      FTableRow.CellCount := FTableColCount;
      FBlocks := FTableRow.Cells[FTableColCount - 1].Blocks; // starting new cell
    end
    else if ACtrl = 'row' then // end of a row
    begin
      if FTableRow.Cells[FTableColCount - 1].Blocks.Count = 0 then
        FTableRow.CellCount := FTableRow.CellCount - 1;
      if FTableLastRow then
      begin
        FlushTable;
        FTableLastRow := False;
        FTableColCount := 0;
      end else
      begin
        ActiveTable.RowCount := ActiveTable.RowCount + 1;
        ActiveTable.ColCount := Max(ActiveTable.ColCount, FTableRow.CellCount);
        FTableRow := ActiveTable.Rows[ActiveTable.RowCount - 1];
        FTableColCount := 1;
        FTableRow.CellCount := FTableColCount;
        FBlocks := FTableRow.Cells[FTableColCount - 1].Blocks; // starting new cell
      end;
      FTableCol := -1;
      FTableCell := nil;
      FTableBorder := alNone;
    end
    else if ACtrl = 'lastrow' then
    begin
      FTableLastRow := True;
    end
    else if ACtrl = 'trowd' then
    begin
      // this block comes again after definition of the row and is used to read row/cell properties
      // we don't support reading cell properties before entire row is defined
      FTableCol := 0;
      FTableCell := FTableRow.Cells[FTableCol];
    end
    else if (FTableCol >= 0) and (FTableCell <> nil) then
    begin
      // read row properties
      if ACtrl = 'trpaddb' then
      begin
        // we silently assume trgaph will come before trpaddx
        for I := 0 to FTableRow.CellCount - 1 do
          FTableRow.Cells[I].BlockStyle.BottomPadding := TwipsToPoints(AParam);
      end
      else if ACtrl = 'trpaddl' then
      begin
        // we silently assume trgaph will come before trpaddx
        for I := 0 to FTableRow.CellCount - 1 do
          FTableRow.Cells[I].BlockStyle.LeftPadding := TwipsToPoints(AParam);
      end
      else if ACtrl = 'trpaddr' then
      begin
        // we silently assume trgaph will come before trpaddx
        for I := 0 to FTableRow.CellCount - 1 do
          FTableRow.Cells[I].BlockStyle.RightPadding := TwipsToPoints(AParam);
      end
      else if ACtrl = 'trpaddt' then
      begin
        // we silently assume trgaph will come before trpaddx
        for I := 0 to FTableRow.CellCount - 1 do
          FTableRow.Cells[I].BlockStyle.TopPadding := TwipsToPoints(AParam);
      end
      else if ACtrl = 'trgaph' then
      begin
        Value := TwipsToPoints(AParam);
        for I := 0 to FTableRow.CellCount - 1 do
          FTableRow.Cells[I].BlockStyle.ContentPadding.AssignFromValues(Value, Value, Value, Value);
      end
      // read cell properties
      else if ACtrl = 'clbrdrb' then
        FTableBorder := alBottom
      else if ACtrl = 'clbrdrl' then
        FTableBorder := alLeft
      else if ACtrl = 'clbrdrr' then
        FTableBorder := alRight
      else if ACtrl = 'clbrdrt' then
        FTableBorder := alTop
      else if ACtrl = 'brdrw' then
      begin
        case FTableBorder of
          alBottom: FTableCell.BlockStyle.BorderWidths.Bottom := TwipsToPoints(AParam);
          alLeft: FTableCell.BlockStyle.BorderWidths.Left := TwipsToPoints(AParam);
          alRight: FTableCell.BlockStyle.BorderWidths.Right := TwipsToPoints(AParam);
          alTop: FTableCell.BlockStyle.BorderWidths.Top := TwipsToPoints(AParam);
        end;
      end
      else if ACtrl = 'brdrnone' then
      begin
        case FTableBorder of
          alBottom: FTableCell.BlockStyle.BorderWidths.Bottom := 0;
          alLeft: FTableCell.BlockStyle.BorderWidths.Left := 0;
          alRight: FTableCell.BlockStyle.BorderWidths.Right := 0;
          alTop: FTableCell.BlockStyle.BorderWidths.Top := 0;
        end;
      end
      else if ACtrl = 'clcbpat' then
      begin
        FTableCell.BlockStyle.Brush.Color := FColorTable.GetColor(AParam - 1);
      end
      else if ACtrl = 'cellx' then
      begin
        // this command comes as the last for current cell
        FTableCell.RequiredWidth := TwipsToPoints(AParam);
        Inc(FTableCol);
        if FTableCol < FTableRow.CellCount then
          FTableCell := FTableRow.Cells[FTableCol]
        else
          FTableCell := nil; // error in RTF, ignore next properties
      end;
    end else
      Result := False;
  end else
    Result := False;
end;

function TKMemoRTFReader.ReadTextFormatting(const ACtrl: AnsiString;
  AParam: Integer; ATextStyle: TKMemoTextStyle): Boolean;
begin
  Result := True;
  if ACtrl = 'plain' then
  begin
    ATextStyle.Assign(FMemo.TextStyle);
  end
  else if ACtrl = 'f' then
  begin
    ApplyFont(ATextStyle, AParam);
  end
  else if ACtrl = 'b' then
  begin
    if AParam = 0 then
      ATextStyle.Font.Style := ATextStyle.Font.Style - [fsBold]
    else
      ATextStyle.Font.Style := ATextStyle.Font.Style + [fsBold];
  end
  else if ACtrl = 'i' then
  begin
    if AParam = 0 then
      ATextStyle.Font.Style := ATextStyle.Font.Style - [fsItalic]
    else
      ATextStyle.Font.Style := ATextStyle.Font.Style + [fsItalic];
  end
  else if ACtrl = 'ul' then
  begin
    if AParam = 0 then
      ATextStyle.Font.Style := ATextStyle.Font.Style - [fsUnderline]
    else
      ATextStyle.Font.Style := ATextStyle.Font.Style + [fsUnderline];
  end
  else if ACtrl = 'strike' then
  begin
    if AParam = 0 then
      ATextStyle.Font.Style := ATextStyle.Font.Style - [fsStrikeout]
    else
      ATextStyle.Font.Style := ATextStyle.Font.Style + [fsStrikeout];
  end
  else if ACtrl = 'caps' then
  begin
    ATextStyle.Capitals := tcaNormal;
  end
  else if ACtrl = 'scaps' then
  begin
    ATextStyle.Capitals := tcaSmall;
  end
  else if ACtrl = 'fs' then
  begin
    ATextStyle.Font.Size := AParam div 2;
  end
  else if ACtrl = 'cf' then
  begin
    ATextStyle.Font.Color := FColorTable.GetColor(AParam - 1);
  end
  else if ACtrl = 'cb' then
  begin
    ATextStyle.Brush.Color := FColorTable.GetColor(AParam - 1);
  end
  else if ACtrl = 'highlight' then
  begin
    ApplyHighlight(ATextStyle, AParam);
  end
  else
    Result := False;
end;

function TKMemoRTFReader.TwipsToPoints(AValue: Integer): Integer;
begin
  Result := DivUp(AValue, 20);
end;

end.
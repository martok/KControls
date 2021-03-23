{ @abstract(This file is an extension to the KControls project.)
  @author(Martok)

  Copyright (c) 2021 Martok<BR><BR>

  <B>License:</B><BR>
  This code is licensed under BSD 3-Clause Clear License, see file License.txt or https://spdx.org/licenses/BSD-3-Clause-Clear.html.
}
unit xkMemoHelper;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, kmemo, kfunctions, kmemortf;

type

  TKMemoVisHelper = class(TKMemo)
  end;

  TKMemoBlockAddress = array of TKMemoBlockIndex;


  { TKMemoHelper }

  TKMemoHelper = class helper for TKMemo

  public
    procedure AllSaveToRTFStream(AStream: TStream; ASelectedOnly: Boolean = False; AReadableOutput: Boolean = False);
    function BlockToBlockAddress(aBlock: TKMemoBlock): TKMemoBlockAddress;
    function BlockAddressToBlock(aAddr: TKMemoBlockAddress): TKMemoBlock;
    procedure UpdateAll(CallInvalidate: Boolean);
  end;

  { TKMemoBlockHelper }

  TKMemoBlockHelper = class helper for TKMemoBlock
    procedure SetInnerText(aText: TKString);
    function GetNearestTable(out Col, Row: integer): TKMemoTable;
  end;

  { TKMemoTableHelper }

  TKMemoTableHelper = class helper for TKMemoTable
    procedure FixupCellContents;
  end;

operator := (A: TKMemoBlockAddress): String;
procedure DumpBlocks(blocks: TKMemoBlocks; Indent: String = '');

implementation

operator:=(A: TKMemoBlockAddress): String;
var
  i: Integer;
begin
  Result:= '[';
  for i:= 0 to high(A) do begin
    if i > 0 then
      Result += ',';
    Result += IntToStr(A[i]);
  end;
  Result += ']';
end;


procedure DumpBlocks(blocks: TKMemoBlocks; Indent: String = '');
var
  i: Integer;
  b: TKMemoBlock;
begin
  for i:= 0 to blocks.Count - 1 do begin
    b:= blocks[i];
    Write(Indent, i:5, ' ', b.ClassName, ' ');
    if b is TKMemoTextBlock then
      Write(TKMemoTextBlock(b).Text)
    else if b is TKMemoImageBlock then
      Write(TKMemoImageBlock(b).ImageWidth,'x',TKMemoImageBlock(b).ImageHeight);
    WriteLn;
    if b is TKMemoContainer then
      DumpBlocks(TKMemoContainer(b).Blocks, Indent + ' ');
  end;
end;

{ TKMemoHelper }

procedure TKMemoHelper.AllSaveToRTFStream(AStream: TStream; ASelectedOnly: Boolean; AReadableOutput: Boolean);
var
  Writer: TKMemoRTFWriter;
begin
  Writer := TKMemoRTFWriter.Create(Self);
  try
    Writer.ReadableOutput := AReadableOutput;
    Writer.SaveToStream(AStream, ASelectedOnly, Self.Blocks);
  finally
    Writer.Free;
  end;
end;

function TKMemoHelper.BlockToBlockAddress(aBlock: TKMemoBlock): TKMemoBlockAddress;
var
  bl: TKMemoBlock;
  pb: TKMemoBlocks;
begin
  Result:= [];
  bl:= aBlock;
  while Assigned(bl) do begin
    pb:= bl.ParentBlocks;
    Insert(pb.IndexOf(bl), Result, 0);
    bl:= pb.Parent;
  end;
end;

function TKMemoHelper.BlockAddressToBlock(aAddr: TKMemoBlockAddress): TKMemoBlock;
var
  pb: TKMemoBlocks;
  i: Integer;
begin
  Result:= nil;
  pb:= Blocks;
  for i:= 0 to high(aAddr) do begin
    Result:= pb[aAddr[i]];
    if i = high(aAddr) then
      Exit
    else begin
      if Result is TKMemoContainer then
        pb:= TKMemoContainer(Result).Blocks
      else
        Exit(nil);
    end;
  end;
end;

procedure TKMemoHelper.UpdateAll(CallInvalidate: Boolean);
begin
  UpdateScrollRange(False);
  UpdateEditorCaret;
  UpdateScrollRange(False); // double update, sometimes TKMemoContainer needs more than one
  if CallInvalidate then
    Invalidate;
end;

{ TKMemoBlockHelper }

procedure TKMemoBlockHelper.SetInnerText(aText: TKString);
begin
  if Self is TKMemoTextBlock then
    TKMemoTextBlock(self).Text:= aText
  else if Self is TKMemoContainer then begin
    TKMemoContainer(Self).Blocks.Clear;
    if (aText = #13) or (aText = NewLineChar) then
      TKMemoContainer(Self).Blocks.AddParagraph()
    else
      TKMemoContainer(Self).Blocks.AddTextBlock(aText);
  end;
end;

function TKMemoBlockHelper.GetNearestTable(out Col, Row: integer): TKMemoTable;
var
  p: TKMemoBlock;
begin
  Result:= nil;
  Col:= -1;
  Row:= -1;
  p:= Self;

  while Assigned(p) do begin
    if p is TKMemoTableCell then
      Col:= p.ParentBlocks.IndexOf(p)
    else if p is TKMemoTableRow then
      Row:= p.ParentBlocks.IndexOf(p)
    else if p is TKMemoTable then
      Exit(p as TKMemoTable);
    p:= p.ParentBlocks.Parent;
  end;
end;

{ TKMemoTableHelper }

procedure TKMemoTableHelper.FixupCellContents;
var
  r, c: Integer;
  cell: TKMemoTableCell;
begin
  for r:= 0 to RowCount - 1 do begin
    for c:= 0 to ColCount - 1 do begin
      if CellValid(c, r) then begin
        cell:= Cells[c, r];
        if cell.Blocks.Count = 0 then
          cell.SetInnerText(#13);
      end;
    end;
  end;
end;



end.


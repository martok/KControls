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
  SysUtils, Classes, kmemo, kmemortf;

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

operator := (A: TKMemoBlockAddress): String;

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

end.


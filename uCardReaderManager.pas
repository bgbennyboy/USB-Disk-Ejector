 {
******************************************************
  USB Disk Ejector
  Copyright (c) 2006 - 2015 Bennyboy
  Http://quickandeasysoftware.net
******************************************************
}
{
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

unit uCardReaderManager;

interface

uses
  classes;

type
  TCardReader = packed record
    VendorID: string;
    ProductID: string;
    ProductRevision: string;
  end;


  TCardReaderManager = class
  private
    function GetCardReadersCount: integer;
  public
    CardReaders: array of TCardReader;
    constructor Create();
    destructor Destroy; override;
    procedure ClearCardReaderList;
    procedure DeleteCardReader(const Index: Cardinal);
    function AddCardReader(VendorID, ProductID, ProductRevision: string): boolean;
    property CardReadersCount: integer read GetCardReadersCount;
  end;

implementation

{ TCardReaderManager }

function TCardReaderManager.AddCardReader(VendorID, ProductID,
  ProductRevision: string): boolean;
var
  i: integer;
begin
  result := true;

  //Check it doesnt already exist
  for I := 0 to CardReadersCount - 1 do
  begin
    if (CardReaders[i].VendorID = VendorID) and
       (CardReaders[i].ProductID = ProductID) and
       (CardReaders[i].ProductRevision = ProductRevision) then
       begin
        result := false;
        exit;
       end;
  end;

  SetLength(CardReaders, length(CardReaders) + 1);
  CardReaders[high(CardReaders)].VendorID := VendorID;
  CardReaders[high(CardReaders)].ProductID := ProductID;
  CardReaders[high(CardReaders)].ProductRevision := ProductRevision;
end;

procedure TCardReaderManager.ClearCardReaderList;
begin
  SetLength(CardReaders, 0);
end;

constructor TCardReaderManager.Create;
begin
  SetLength(CardReaders, 0);
end;

procedure TCardReaderManager.DeleteCardReader(const Index: Cardinal);
var
  ALength: Cardinal;
  TailElements: Cardinal;
begin
  ALength := Length(CardReaders);
  Assert(ALength > 0);
  Assert(Index < ALength);
  Finalize(CardReaders[Index]);
  TailElements := ALength - Index;

  if TailElements > 0 then
    Move(CardReaders[Index + 1], CardReaders[Index], SizeOf(TCardReader) * TailElements);

  Initialize(CardReaders[ALength - 1]);
  SetLength(CardReaders, ALength - 1);

end;

destructor TCardReaderManager.Destroy;
begin
  SetLength(CardReaders, 0);
  inherited;
end;

function TCardReaderManager.GetCardReadersCount: integer;
begin
  result:=Length(CardReaders);
end;

end.

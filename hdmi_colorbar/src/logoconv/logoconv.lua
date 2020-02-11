infile = io.open("DVD-logo_256x148_1bit.xpm","r")
outfile = io.open("dvdlogo.mi","wb")

-- 入力ファイル先頭の5行を読み飛ばす
for i=1,5 do infile:read() end

-- 出力ファイルヘッダ作成
outfile:write("#File_format=Bin\n","#Address_depth=37888\n","#Data_width=1\n")

-- 画像データを変換
for y=1,148 do
	s = infile:read()
	str = ""
	for x=1,256 do
		if s:sub(x+1,x+1) == "." then
			outfile:write("0\n")
			str = str .. "0"
		else
			outfile:write("1\n")
			str = str .. "1"
		end
	end
	print(str)
end

infile:close()
outfile:close()

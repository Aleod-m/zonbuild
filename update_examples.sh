#!/usr/bin/env sh

hash="$(zig fetch .)"

zon_files=$(cat<<-TXT
	./examples/simple/build.zig.zon
	./examples/code-gen/build.zig.zon
	./examples/code-gen/gen/build.zig.zon
TXT
);

echo "$hash";

for file in $zon_files ; do
	sed -i -e "s#.hash = \"zonbuild-[0-9]\+\.[0-9]\+\.[0-9]\+-.\+\",#.hash = \"$hash\",#g" "$file";
done

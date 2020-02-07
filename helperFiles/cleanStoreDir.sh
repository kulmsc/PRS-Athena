rm /workdir/sdk2004/prep/*
rm /workdir/sdk2004/logs/*
for i in {1..48}; do
	rm -r /workdir/sdk2004/dir${i}/*
	rm /workdir/sdk2004/store${i}/*
done

import numpy as np
import gzip
import os
import sys

def gzRead(fileName):
        with gzip.open(fileName,"r") as f:
                totalData=[]
		for line in f.read().splitlines():
			totalData.append(line.split('\t'))
	header=totalData[0]
	del totalData[0]
	totalData=np.array(totalData,dtype='float')
        return(totalData,header)

def gzWrite(fileName,toWrite):
        with gzip.open(fileName,'w') as f:
                for line in toWrite:
                        f.write('\t'.join(line)+'\n')

#get the number of subFiles
allFiles=os.listdir('.')
numberSubFiles=0
for data in allFiles:
        if int(data.split("field")[1].split('.')[0]) > numberSubFiles:
                numberSubFiles=int(data.split("field")[1].split('.')[0])
print numberSubFiles,"numberSubFiles"

#split the files into groups by their subFile
master=[[] for _ in range(numberSubFiles)]
for data in allFiles:
        splitData=data.split('.')
	for i in range(numberSubFiles):
		if splitData[0]=="field"+str(i+1):
			master[i].append(data)
print master,"master"

masterLabel=["grandField"+str(i+1)+".gz" for i in range(numberSubFiles)]
for scoreType,scoreLabel in zip(master,masterLabel):
	firstFile=True
	print(scoreLabel)
	for score in scoreType:
		if firstFile:
			scoreTotal,scoreHeader=gzRead(score)
			scoreHeader=np.array(scoreHeader)
			firstFile=False
		else:
			scoreArray,scoreHeader=gzRead(score)
			scoreTotal=scoreTotal+scoreArray
	scoreTotal=scoreTotal.astype("string")
	toWrite=np.vstack((scoreHeader,scoreTotal))
	gzWrite(scoreLabel,toWrite)

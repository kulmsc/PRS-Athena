import socket
import os
import numpy as np
import gzip
import sys

direc=sys.argv[1]
numberSubFiles=int(sys.argv[2])
method=sys.argv[3]

def gzRead(fileName):
	with gzip.open(fileName,"r") as f:
		totalData=f.read().splitlines()
	if len(totalData)>1:
		status="good"
		del totalData[0]
		totalData=np.array(totalData,dtype='float')
	else:
		status="bad"
		totalData=[]
	return(totalData,status)

def gzWrite(fileName,toWrite):
	with gzip.open(fileName,'w') as f:
        	for line in toWrite:
                	f.write('\t'.join(line)+'\n')


#get the host name
#serverNumber = int(socket.gethostname().split('.')[0].split('0')[1])
#serverNumber = serverNumber - 2
serverNumber = 1

#putting the names of each pval type of file into its own list
#allFiles=os.listdir('.')

allFilesReal=os.listdir('.')
allFiles=[]
for q in allFilesReal:
	if q.split('.')[3]==method: #change to either 3 or 1
		allFiles.append(q)
if len(allFiles)==0:
	sys.exit()

master=[[] for _ in range(numberSubFiles)]
for data in allFiles:
	splitData=data.split('.')
	for i in range(numberSubFiles):
		if splitData[5]==str(i+1):  #THIS IS WHERE I CHANGE to either 4 or 5
			master[i].append(data)


fileLength=sum(1 for line in gzip.open(allFiles[0]))



fileNamesLong=[]
for i in range(22):
	tempList=[]
	for poss in os.listdir("/home/kulmsc/athena/forScoring/chr"+str(i+1)):
		if poss[0:5]!="field":
			tempList.append(poss)
	fileNamesLong=fileNamesLong+tempList
fileNames=[x.split('.')[0] for x in fileNamesLong]
fileNames=list(set(fileNames))
filesNames=fileNames.sort()
fileNumber={key: value for key, value in zip(fileNames,range(len(fileNames)))}


masterLabel=["field"+str(i+1) for i in range(numberSubFiles)]
for scoreType,scoreLabel in zip(master,masterLabel):
	scores=np.zeros((fileLength-1,len(fileNames)))
	for data in scoreType:
		fileName=data.split('.')[0]
		fileArray,status=gzRead(data)	

		#THIS IS ADDED
		#print(fileArray)
		try:
                	fileArray[fileArray==float("-inf")]=0
		except:
			print("FAIL")

		if status=="good":
			scores[:,fileNumber[fileName]]=scores[:,fileNumber[fileName]]+fileArray
	
	storeNames=np.array(fileNames)
	scores=scores.astype('string')
	scores=np.vstack((storeNames,scores))
	scores=scores.tolist()
	gzWrite(scoreLabel+'.'+str(direc)+'.'+str(serverNumber)+'.gz',scores)

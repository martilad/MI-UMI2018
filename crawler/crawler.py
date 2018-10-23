import requests
import traceback
from bs4 import BeautifulSoup
from urllib.parse import urlparse
import logging

logger = logging.getLogger('crawler')
logger.setLevel(logging.DEBUG)
# create file handler which logs even debug messages
fh = logging.FileHandler('log.log')
fh.setLevel(logging.DEBUG)
# create formatter and add it to the handlers
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
fh.setFormatter(formatter)
# add the handlers to the logger
logger.addHandler(fh)


blockFiles={'jpg', 'pdf', 'zip', 'rar', 'swg',
 'png', 'tiff', 'doc', 'docx', 'ppt', 'pptx', 'mp3', 'mp4',
 'flac', 'avi', 'mkv', 'mov', 'wav', '7xip', 'exe', 'sh', 'deb'}
fromPage = "https://fit.cvut.cz/"
f = fromPage
#fromPage = "http://knihovna.cvut.cz"


toPage= "http://www.mit.edu/"
contain = "mit.edu"
#contain = 'instagram.com'
#toPage='https://www.instagram.com/fit_ctu/'
#toPage='https://dspace.cvut.cz'
#toPage='https://www.eclipse.org'


mapRoad = {}
mapRoad[fromPage] = None
nodeToProcess = []
setOfProccesedNode = set()
setOfProccesedNode.add(fromPage)




def endPrint(road, pag, f, logger, setOfProccesedNode):
    cnt = 0
    while True:
        if cnt > 1000:
            logger.debug("error reconstruct")
            retur
        cnt += 1
        if pag == f:
            road.append(pag)
            road = " -> ".join(road[::-1])
            road = road + "\n\n"
            with open("road.txt", "a") as text_file:
            	text_file.write(str(len(setOfProccesedNode)))
                text_file.write(road)
                text_file.flush()
                
            return
        road.append(pag)
        pag = mapRoad[pag]
        if pag == None:
            logger.error("error none there")
        logger.debug(str(pag) + " " + str(mapRoad[pag]))


while(True):
    logger.info(fromPage)
    logger.info("queue: " + str(len(nodeToProcess)))
    logger.info("check: " + str(len(setOfProccesedNode)))

    try:
        page = requests.get(fromPage)
        soup = BeautifulSoup(page.text, "html.parser")
        links = soup.find_all('a', href=True)
        urls = [i['href'] for i in links if bool(urlparse(i['href']).scheme)]
        domains = {urlparse(i).netloc for i in urls}
        if urlparse(toPage).netloc in domains:
            logger.info("I find the walk from {} to {}.".format(f, toPage))
            endPrint([toPage], fromPage, f, logger, setOfProccesedNode)
        for url in urls:
            if contain in url:
                logger.info("I find the walk from {} to {}.".format(f, url))
                endPrint([url], fromPage, f, logger, setOfProccesedNode)
            if url.split('.')[-1] in blockFiles:
                logger.info("Not download file: " + str(url))
                continue
            if url not in setOfProccesedNode:
                setOfProccesedNode.add(url)
                nodeToProcess.append(url)
                mapRoad[url] = fromPage
        fromPage = nodeToProcess[0]
        del nodeToProcess[0]

    except Exception as e:
        logger.debug(e)
        traceback.print_exc()
        logger.debug(traceback.format_exc())
        fromPage = nodeToProcess[0]
        del nodeToProcess[0]
        continue


    
    
    

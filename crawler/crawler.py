import requests
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



blockFiles={'jpg', 'pdf', 'zip', 'rar', 'swg', 'png', 'tiff', 'doc', 'docx', 'ppt', 'pptx'}
fromPage = "https://fit.cvut.cz/"
f = fromPage
#fromPage = "http://knihovna.cvut.cz"


toPage= "http://www.mit.edu/"
#toPage='https://www.instagram.com/fit_ctu/'
#toPage='https://dspace.cvut.cz'
#toPage='https://www.eclipse.org'


mapRoad = {}
mapRoad[fromPage] = None
nodeToProcess = []
setOfProccesedNode = set()

while(True):
    logger.info(fromPage)
    logger.info("queue: " + str(len(nodeToProcess)))
    logger.info("check: " + str(len(setOfProccesedNode)))

    try:
        page = requests.get(fromPage)
    except:
        prevPage = fromPage
        fromPage = nodeToProcess.pop()
    soup = BeautifulSoup(page.text, "html.parser")
    links = soup.find_all('a', href=True)
    urls = [i['href'] for i in links if bool(urlparse(i['href']).scheme)]
    domains = {urlparse(i).netloc for i in urls}
    if urlparse(toPage).netloc in domains:
        logger.info("I find the walk from {} to {}.".format(f, toPage))
        road = [toPage]
        pag = fromPage
        while True:
            if mapRoad[pag] != None:
                road.append(pag)
                pag = mapRoad[pag]
            else:
                road.append(pag)
                with open("road.txt", "w") as text_file:
                    text_file.write(" -> ".join(road[::-1]))
                print(" -> ".join(road[::-1]))
                assert(False)
    for url in urls:
        if url.split('.')[-1] in blockFiles:
            logger.info("Not download file: " + str(url))
            continue
        if url not in setOfProccesedNode:
            setOfProccesedNode.add(url)
            nodeToProcess.append(url)
            mapRoad[url] = fromPage
    fromPage = nodeToProcess[0]
    del nodeToProcess[0]
    
    

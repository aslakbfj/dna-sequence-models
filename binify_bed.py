
import heapq

class BedBinner:
    def __init__(self, file_path, bin_width=200, min_overlap=100):
        self.bin_width = bin_width
        self.min_overlap = min_overlap
        self.file = open(file_path, 'r')
        # initial values:
        self.bin = -1
        self.chr = ""
        self.overlap = 0
        self.nextLine()
    def nextLine(self):
        next_line = self.file.readline()
        if not next_line:
            self.file.close()
            self.bin=None
            return
        # print(next_line)
        [nextchr, start, end] = next_line.strip().split('\t')[0:3]
        self.start = int(start)
        self.end = int(end)
        nextbin = self.start - self.start % self.bin_width
        if self.chr != nextchr:
            # if new chromosome then reset overlap
            #print(f'Chromosome: {nextchr}')
            self.bin = nextbin
            self.chr = nextchr
            self.overlap = 0
        elif nextbin > self.bin:
            # if bin has changed then reset overlap.
            # Note that the nextbin can be before current bin in some cases. If so, keep current
            self.bin = nextbin
            self.overlap = 0
        # check overlap. Get nextLine if insufficiant.
        self.overlap += min(self.end, self.bin + self.bin_width) - max(self.start,self.bin)
        #print(f'overlap = {self.overlap}')
        if( self.overlap < self.min_overlap ):
            if( self.end > self.bin + self.bin_width ):
              # overlap migth be insufficient if only the start of the peak is inside bin
              # in that case we should move to the next bin 
              self.nextBin()
            else:
              self.nextLine()
    def nextBin(self):
        if( self.bin == None):
          return
        self.bin += self.bin_width
        #print(f'nextBin {self.bin}-{self.bin+self.bin_width}')
        # check overlap. Get nextLine if insufficiant.
        self.overlap = max(0, min(self.end, self.bin + self.bin_width) - max(self.start,self.bin))
        #print(f'overlap =  {self.overlap}')
        if( self.overlap < self.min_overlap ):
            self.nextLine()
    @property
    def currentBin(self):
        if( self.bin == None):
          return( None )
        return( (self.chr, self.bin) )


class MultiBedbinner:
    def __init__(self, file_paths, bin_width=200, min_overlap=100):
        self.bedBinners = [BedBinner(file_path, bin_width, min_overlap) for file_path in file_paths]
        self.pq = []
        for i, b in enumerate(self.bedBinners):
            bin = b.currentBin
            if bin:
                heapq.heappush(self.pq, (bin, i ))

    def __iter__(self):
        return self

    def __next__(self):
        if not self.pq:
            raise StopIteration
        
        binValues=[0] * len(self.bedBinners)

        # Peek at the heap to see what is the next bin
        nextbin = self.pq[0][0]
        # pop all items in that bin
        while self.pq and self.pq[0][0] == nextbin:
          # get file index
          i = heapq.heappop(self.pq)[1]
          binValues[i] = 1
          # get next bin for that file and push to queue
          self.bedBinners[i].nextBin()
          bin = self.bedBinners[i].currentBin
          if bin:
              heapq.heappush(self.pq, (bin, i ))
        
        return (nextbin,binValues)
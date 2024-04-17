import time
import os
import click
import heapq
from pyfaidx import Fasta

class BedBinner:
    def __init__(self, file_path, bin_width=200, min_overlap=100):
        self.bin_width = bin_width
        self.min_overlap = min_overlap
        self.file = open(file_path, 'r')
        # initial values:
        self.bin = -1
        self.chr = ""
        self.overlap = 0
        self.__nextLine()
    def __nextLine(self):
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
              self.__nextLine()
    def nextBin(self):
        if( self.bin == None):
          return
        self.bin += self.bin_width
        #print(f'nextBin {self.bin}-{self.bin+self.bin_width}')
        # check overlap. Get nextLine if insufficiant.
        self.overlap = max(0, min(self.end, self.bin + self.bin_width) - max(self.start,self.bin))
        #print(f'overlap =  {self.overlap}')
        if( self.overlap < self.min_overlap ):
            self.__nextLine()
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
    

def multibed_to_tsv(peakfiles, bin_width, min_overlap, outstream, genome_fasta, seq_length, exclude):
    if exclude:
        # optianally add blacklist as first bed file
        peakfiles = [exclude] + peakfiles

    last_update_time = time.time() - 1  # Initialize to ensure immediate first update
    bins_output = 0
    excluded_bins = 0

    for ((chr,bin_start), binValues) in MultiBedbinner(peakfiles, bin_width, min_overlap):
      if exclude:
          # skip if this bin is in an exclusion region
          if binValues[0] == 1:
              if sum(binValues[1:])>0: # check if there was any peaks in the bin anyway
                excluded_bins += 1
              continue
          binValues = binValues[1:] # drop the exclude value

      seq_start=bin_start+ bin_width//2 - seq_length//2
      seq_end=seq_start+seq_length
      seq = genome_fasta[chr][seq_start:seq_end].seq
      seq = seq.upper() # perhaps check for N's, because there are a lot of N's
      if len(seq) == 1000 and 'N' not in seq:
        outstream.write(f'{chr}:{seq_start+1}-{seq_end}\t{seq}\t' + '\t'.join(map(str, binValues)) + "\n")
        bins_output += 1
      if time.time() - last_update_time >= 3:
          progress_message = f"Current chr: {chr}, Bins output: {bins_output}"
          if exclude:
              progress_message += f", Excluded bins: {excluded_bins}"
          click.echo(progress_message)
          last_update_time = time.time()

    # Print final count
    progress_message = f"Total bins output: {bins_output}"
    if exclude:
        progress_message += f", Total excluded bins: {excluded_bins}"
    print(progress_message)


# get command line parameters
@click.command()
@click.option('--bedlist', type=click.Path(exists=True), required=True, help='A file containing a list of paths to bed files (one per line).')
@click.option('--fasta', type=click.Path(exists=True), required=True, help='Genome sequence fasta file.')
@click.option('--outfile', type=click.Path(), required=True, help='Output .tsv file.')
@click.option('--exclude', type=click.Path(exists=True), default=None, help='(Optional) A bed file with regions to exclude, a.k.a. blacklist.')
@click.option('--seq_length', type=int, default=1000, help='Number of basepairs to extract per window (default: 1000).')
@click.option('--bin_width', type=int, default=200, help='Bin width in number of basepairs (default: 200).')
@click.option('--min_overlap', type=int, default=None, help='Minimum overlap between peaks and bin in number of basepairs (default: bin_width/2).')


def main(bedlist, fasta, outfile, exclude, seq_length, bin_width, min_overlap):
    if min_overlap is None:
        min_overlap = bin_width // 2
    
    click.echo(f"Bedlist file: {bedlist}")
    with open(bedlist, 'r') as file:
        peakfiles = file.readlines()
    peakfiles = [line.strip() for line in peakfiles]
    click.echo(f"  Number of bed files: {len(peakfiles)}")

    click.echo(f"Exclude file: {exclude}" if exclude else "Exclude file: None")
    click.echo(f"Fasta file: {fasta}")
    click.echo(f"Sequence length: {seq_length}")
    click.echo(f"Bin width: {bin_width}")
    click.echo(f"Minimum overlap: {min_overlap}")

    if os.path.exists(fasta+".fai"):
        genome_fasta = Fasta(fasta)
    else:
        click.echo("Indexing fasta file...")
        genome_fasta = Fasta(fasta)
        click.echo("Indexing complete.")

    with open(outfile, 'w') as file:
      multibed_to_tsv(peakfiles, bin_width, min_overlap, outstream=file, 
                      genome_fasta=genome_fasta, seq_length=seq_length,
                      exclude = exclude)

if __name__ == '__main__':
    main()

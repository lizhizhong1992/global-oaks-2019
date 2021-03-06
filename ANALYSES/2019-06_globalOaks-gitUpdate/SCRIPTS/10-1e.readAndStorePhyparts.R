## read in phyparts output, format for plotting
library(ggplot2)

# 0. variables
verbose = T # whether to chat at you when putting files into data.frame

# 1. read in all files, store in list
phyParts.files <- lapply(dir('phyparts_2019-05-21', patt = 'conflict|concord', full = T), readLines)

# 2. clean list names to indicate just locus name and support / conflict
names(phyParts.files) <- dir('phyparts_2019-05-21', patt = 'conflict|concord') %>%
  gsub(pattern = 'phyPartsOut.txt.', replacement = '', fixed = T)

# 3. create data frame with columns locus, node, Information
phyParts.n <- sapply(phyParts.files, length) %>% sum # total numer of rows to process
workingRows = 0 # starting row for writing data
phyParts.df <- data.frame(locus = rep(NA, phyParts.n),
                          node = rep(NA, phyParts.n),
                          info = rep(NA, phyParts.n))
# 4. go through each support and conflict file and store each line in
#     one line of the data frame, filling in the columns
for(i in names(phyParts.files)) {
  message(paste('doing file', i))
  workingRows = seq(from = max(workingRows) + 1,
                    to = max(workingRows) + length(phyParts.files[[i]])
                    )
  infTemp <- strsplit(i, '.node.', fixed = T)[[1]][1]
  nodeTemp <- strsplit(i, '.node.', fixed = T)[[1]][2]
  locTemp <- phyParts.files[[i]] %>%
                strsplit(split = 'squashed.|.tre') %>%
                sapply(., '[', 3) # takes the third element of each name, which is the locus
  nTemp <- length(locTemp)
  phyParts.df[workingRows, 'locus'] <- locTemp
  phyParts.df[workingRows, 'node'] <- rep(nodeTemp, nTemp)
  phyParts.df[workingRows, 'info'] <- rep(infTemp, nTemp)
}

# 5. Add a column of chromosomes and genome positions from the mapping matrix
phyParts.df$chrom <- oaks.map$uniques[phyParts.df$locus, 'chrom']
phyParts.df$cleanStart <- oaks.map$uniques[phyParts.df$locus, 'cleanStart']

# 6. Add an additional column that is linear genome position by adding start
#     position of each to bp
chromStarts <- aggregate(oaks.genomeScaffs$Position.P, list(oaks.genomeScaffs$Pseudomolecule.ID), min)
row.names(chromStarts)<- chromStarts$Group.1
phyParts.df$genomeLinStart <- phyParts.df$cleanStart + chromStarts[phyParts.df$chrom, 'x']

# write a relabelled treeFile for node identification
phyParts.key <- readLines('phyparts_2019-05-21/phyPartsOut.txt.node.key.tre')
for(i in 1:dim(radMetaOut)[1]) {
  phyParts.key <- gsub(paste(row.names(radMetaOut)[i], ')', sep = ''),
                       paste(radMetaOut$tip[i], ')', sep = ''),
                       phyParts.key)
  phyParts.key <- gsub(paste(row.names(radMetaOut)[i], ',', sep = ''),
                       paste(radMetaOut$tip[i], ',', sep = ''),
                       phyParts.key)
                     }
phyParts.key <- sapply(strsplit(phyParts.key, ' ', fixed = T), '[[', 2)
writeLines(phyParts.key, 'phyparts_2019-05-21/phyPartsOut.txt.node.key-renamed.tre')

phyParts.key.tr <- lapply(phyParts.key, function(x) read.tree(text = paste(x, ';', sep = '')))
names(phyParts.key.tr) <- as.character(0:(length(phyParts.key)-1))
dir.create('phyparts.key')
for(i in names(phyParts.key.tr)) {
  jpeg(paste('phyparts.key/node', i, 'jpg', sep = '.'), 1500, 2500)
  plot(phyParts.key.tr[[i]], main = paste('node', i), cex = 3, cex.main = 4)
  dev.off()
}

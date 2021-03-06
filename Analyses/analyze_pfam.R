##### analyze_PFAM.R #####
# Kuan-lin Huang @ WashU 2017 July
# updated 2017 Dec
# updated 2018 April

### dependencies ###
bdir = "/Users/khuang/Box\ Sync/Ding_Lab/Projects_Current/hotpho_data"
setwd(bdir)
source("Analyses/hotpho_analyses_functions.R")

# PFAM file
PFAM_f = "/Users/khuang/Box\ Sync/Ding_Lab/Projects_Current/hotpho_data/data/pdb_pfam_mapping.txt.gz"

##### CLUSTERs #####

annotated_cluster$Gene_site = paste(annotated_cluster$Gene_Drug,annotated_cluster$Mutation_Gene)

PFAM = read.table(header=T, quote = "", sep="\t", stringsAsFactors = F, file = gzfile(PFAM_f))
site_f = "/Users/khuang/Box\ Sync/Ding_Lab/Projects_Current/hotpho_data/HotSpot3D/Data_201805/3D_Proximity.musites.gz"
site = read.table(header=T, quote = "", sep="\t", stringsAsFactors = F, fill =T, file = gzfile(site_f))
site_uniq = site[!duplicated(paste(site$Gene1,site$Mutation1,site$Transcript2,site$TranscriptPosition2)),]
site_uniq$PDB_ID =gsub(".* (.*) .*","\\1",site_uniq$DistanceInfo)

### annotate pFAM name
site_uniq$PFAM_Name1 = NA
site_uniq$PFAM_Name2 = NA
site_uniq$PFAM_desc1 = NA
site_uniq$PFAM_desc2 = NA
for (i in 1:nrow(site_uniq)){
  PDB_ID = site_uniq$PDB_ID[i]
  pfam = PFAM[PFAM$PDB_ID == PDB_ID,]
  if (nrow(pfam) > 0){
    for (k in 1:nrow(pfam)){
      if (site_uniq$Position1[i] > pfam$PdbResNumStart[k] & site_uniq$Position1[i] < pfam$PdbResNumEnd[k]) {
        site_uniq$PFAM_Name1[i] = pfam$PFAM_Name[k]
        site_uniq$PFAM_desc1[i] = pfam$PFAM_desc[k]
      }
      if (site_uniq$Position2[i] > pfam$PdbResNumStart[k] & site_uniq$Position2[i] < pfam$PdbResNumEnd[k]) {
        site_uniq$PFAM_Name2[i] = pfam$PFAM_Name[k]
        site_uniq$PFAM_desc2[i] = pfam$PFAM_desc[k]
      }
    }
  }
}

head(site_uniq)

mutPFAM1 = site_uniq[,which(colnames(site_uniq) %in% c("Gene1","Mutation1","PFAM_Name1","PFAM_desc1"))]
sitePFAM1 = site_uniq[,which(colnames(site_uniq) %in% c("Gene2","Site2","PFAM_Name2","PFAM_desc2"))]
mutPFAM1$Gene_site = paste(mutPFAM1$Gene1,mutPFAM1$Mutation1)
sitePFAM1$Gene_site = paste(sitePFAM1$Gene2,sitePFAM1$Site2)
colnames(mutPFAM1)=c("Gene","Mutation","PFAM_Name","PFAM_desc","Gene_site")
colnames(sitePFAM1)=c("Gene","Mutation","PFAM_Name","PFAM_desc","Gene_site")
musitePFAM = rbind(mutPFAM1,sitePFAM1) # 11477527  lines
musitePFAM$Gene_site_pfam = paste(musitePFAM$Gene,musitePFAM$Gene_site,musitePFAM$PFAM_Name)
musitePFAM = musitePFAM[!duplicated(musitePFAM$Gene_site_pfam),] # 110176 lines
# some sites have more than one feature musitePFAM[duplicated(musitePFAM$Gene_site),]

annotated_cluster$site_type = "Mutation"
annotated_cluster$site_type[annotated_cluster$Alternate=="ptm"]= "Phosphosite"
annotated_cluster$coord = as.numeric(gsub("p.[A-Z]([0-9]+)[A-Z]*","\\1",annotated_cluster$Mutation_Gene))
annotated_cluster$inCPTAC = FALSE
annotated_cluster$inCPTAC[paste(annotated_cluster$Transcript,annotated_cluster$Mutation_Gene) %in% paste(cptac_site$ensembl_transcript_id,cptac_site$amino_acid_residue)]=TRUE

annotated_cluster_feature = merge(annotated_cluster, musitePFAM, by="Gene_site", all.x=T)
annotated_cluster_feature$site_type = "Mutation"
annotated_cluster_feature$site_type[annotated_cluster_feature$Alternate=="ptm"]= "Phosphosite" 


# histone?
histones = read.table("input/histones.tsv",header=F,sep="\t")
histone_genes = histones[,1]
annotated_cluster_h = annotated_cluster[annotated_cluster$Gene_Drug %in% histone_genes,]
annotated_cluster_h$SubFamily = gsub("[A-Z]+$","",annotated_cluster_h$Gene_Drug) # subfamily for histones:https://en.wikipedia.org/wiki/Histone#Actively_transcribed_genes
annotated_cluster_h$SubFamily[annotated_cluster_h$SubFamily=="H2"] = "H2AF"  
annotated_cluster_h_hybrid = annotated_cluster_h[annotated_cluster_h$Type=="Hybrid",]

annotated_cluster_feature_h = annotated_cluster_feature[annotated_cluster_feature$Gene_Drug %in% histone_genes,]
annotated_cluster_feature_h$SubFamily = gsub("[A-Z]+$","",annotated_cluster_feature_h$Gene_Drug) # subfamily for histones:https://en.wikipedia.org/wiki/Histone#Actively_transcribed_genes
annotated_cluster_feature_h$SubFamily[annotated_cluster_feature_h$SubFamily=="H2"] = "H2AF"  
annotated_cluster_feature_h_hybrid = annotated_cluster_feature_h[annotated_cluster_feature_h$Type=="Hybrid",]

  p = ggplot(annotated_cluster_feature_h_hybrid,aes(x = coord, y=Gene_Drug, shape=site_type, color = PFAM_desc, fill = PFAM_desc))
  p = p + facet_grid(SubFamily~.,scale="free",space="free")
  p = p + geom_point(alpha=0.3) + theme_bw()
  #p = p + geom_text_repel(aes(label=ifelse(inCPTAC,Mutation_Gene,NA)))
  p = p + labs(x = "Protein coordinate", y="Gene")
    #p = p + xlim(0,1250)
  p = p + theme(axis.title = element_text(size=12), axis.text.x = element_text(colour="black", size=10, angle = 90, vjust=0.5), axis.text.y = element_text(colour="black", size=12))#element_text(colour="black", size=14))
  #p = p + theme(legend.position = "bottom")
  p
  fn = paste("output/histone_domain_sites_mut_site_linear.plot.pdf",sep=".")
  ggsave(file=fn, w=8, useDingbats=FALSE)
# for (subFamily in unique(annotated_cluster_feature_h_hybrid$SubFamily)){
#   annotated_cluster_feature_h_hybrid_f = annotated_cluster_feature_h_hybrid[annotated_cluster_feature_h_hybrid$SubFamily==subFamily,]
#   top_feat = names(table(annotated_cluster_feature_h_hybrid_f$PFAM_desc)[1:5])
#   annotated_cluster_feature_h_hybrid_f$FeaturePlot = annotated_cluster_feature_h_hybrid_f$PFAM_desc
#   annotated_cluster_feature_h_hybrid_f$FeaturePlot[!(annotated_cluster_feature_h_hybrid_f$FeaturePlot %in% top_feat)] ="Other" 
#   
#   p = ggplot(annotated_cluster_feature_h_hybrid_f,aes(x = coord, y=Gene_Drug, shape=site_type, color = FeaturePlot, fill = FeaturePlot))
#   p = p + facet_grid(SubFamily~.,scale="free",space="free")
#   #p = p + facet_grid(Family~.,scale="free",space="free")
#   #p = p + facet_grid(GroupName~.,scale="free",space="free")
#   p = p + geom_point(alpha=0.3) + theme_bw()
#   #p = p + geom_text_repel(aes(label=ifelse(inCPTAC,Mutation_Gene,NA)))
#   p = p + labs(x = "Protein coordinate", y="Gene") 
#     #p = p + xlim(0,1250)
#   p = p + theme(axis.title = element_text(size=12), axis.text.x = element_text(colour="black", size=10, angle = 90, vjust=0.5), axis.text.y = element_text(colour="black", size=12))#element_text(colour="black", size=14))
#   #p = p + theme(legend.position = "bottom")
#   p
#   fn = paste("output/histone_domain_sites_mut_site_linear.plot",subFamily,"pdf",sep=".")
#   ggsave(file=fn, w=8, useDingbats=FALSE)
# }


# kinase
annotated_cluster_feature_k_cluster = annotated_cluster_feature$Cluster[!is.na(annotated_cluster_feature$PFAM_desc) & 
                                     annotated_cluster_feature$PFAM_desc=="Protein tyrosine kinase" | annotated_cluster_feature$PFAM_desc=="Protein kinase domain"]
annotated_cluster_feature_k = annotated_cluster_feature[annotated_cluster_feature$Cluster %in% annotated_cluster_feature_k_cluster,]
annotated_cluster_feature_k_hybrid = annotated_cluster_feature_k[annotated_cluster_feature_k$Type=="Hybrid" &
                                                                   annotated_cluster_feature_k$Gene_Drug %in% cancer_gene,]
colnames(manning_kinome_wgene_map)[4] = "Gene_Drug"
annotated_cluster_feature_k_hybrid_m = merge(annotated_cluster_feature_k_hybrid,manning_kinome_wgene_map,by="Gene_Drug",all.x=T)
p = ggplot(annotated_cluster_feature_k_hybrid_m,aes(x = coord, y=Gene_Drug, color=site_type))
#p = p + facet_grid(Family~.,scale="free",space="free")
p = p + facet_grid(GroupName~.,scale="free",space="free")
p = p + geom_point(alpha=0.3) + theme_bw()
p = p + geom_text_repel(aes(label=ifelse(inCPTAC & !duplicated(Mutation_Gene),Mutation_Gene,NA)))
p = p + labs(x = "Protein coordinate", y="Gene")
p = p + xlim(0,1250)
p = p + theme(axis.title = element_text(size=12), axis.text.x = element_text(colour="black", size=10, angle = 90, vjust=0.5), axis.text.y = element_text(colour="black", size=12))#element_text(colour="black", size=14))
p
ggsave(file="output/kinase_domain_sites_mut_site_linear.plot.pdf", useDingbats=FALSE)

# > table(annotated_cluster_feature$Type)
# 
# Hybrid  Mut_Only Site_Only 
# 45195     51224      4749 
# first is NA
top_feature = names(table(annotated_cluster_feature$PFAM_desc)[order(table(annotated_cluster_feature$PFAM_desc),decreasing = T)][2:21]) 
annotated_cluster_feature_top = annotated_cluster_feature[annotated_cluster_feature$PFAM_desc %in% top_feature,]
top_feature_count = data.frame(table(annotated_cluster_feature_top$PFAM_desc,annotated_cluster_feature_top$site_type))

p = ggplot(top_feature_count,aes(x = Var1, y=Freq, fill=Var2))
p = p + geom_bar(stat="identity") + theme_bw()
p = p + labs(x = "Feature", y="Counts")
p = p + theme(axis.title = element_text(size=12), axis.text.x = element_text(colour="black", size=10, angle = 90, vjust=0.5), axis.text.y = element_text(colour="black", size=12))#element_text(colour="black", size=14))
p
ggsave(file="output/top20_PFAM_features.pdf", useDingbats=FALSE)

top_gene_in_top_20_feature = names(table(annotated_cluster_feature_top$Gene_Drug)[order(table(annotated_cluster_feature_top$Gene_Drug),decreasing = T)][1:20])
annotated_cluster_feature_top_topG = annotated_cluster_feature_top[annotated_cluster_feature_top$Gene_Drug %in% top_gene_in_top_20_feature,]
top_feature_gene_count = data.frame(table(annotated_cluster_feature_top_topG$PFAM_desc,annotated_cluster_feature_top_topG$Gene_Drug,annotated_cluster_feature_top_topG$site_type))
top_feature_gene_count$Freq_plot = top_feature_gene_count$Freq
top_feature_gene_count$Freq_plot[top_feature_gene_count$Freq_plot>20]=20

p = ggplot(top_feature_gene_count,aes(x = Var1, size=Freq_plot, y=Var2, color=Var1))
p = p + facet_grid(.~Var3)
p = p + geom_point() + theme_bw() + scale_size_area()#range = c(0,10))
p = p + labs(x = "Feature", y="Gene")
p = p + geom_text(aes(label=ifelse(Freq > 10, Freq, NA)), color="black",size=3)
p = p + theme(axis.title = element_text(size=12), axis.text.x = element_text(colour="black", size=10, angle = 90, vjust=0.5), axis.text.y = element_text(colour="black", size=12))#element_text(colour="black", size=14))
p
ggsave(file="output/top20_PFAM_features_20gene.pdf", height=7, width=9, useDingbats=FALSE)

for (type in unique(annotated_cluster_feature$Type)) {
  annotated_cluster_feature_t = annotated_cluster_feature[annotated_cluster_feature$Type==type,]
  top_feature = names(table(annotated_cluster_feature_t$PFAM_desc)[order(table(annotated_cluster_feature_t$PFAM_desc),decreasing = T)][2:21])
  annotated_cluster_feature_t_top = annotated_cluster_feature_t[annotated_cluster_feature_t$PFAM_desc %in% top_feature,]
  top_feature_count = data.frame(table(annotated_cluster_feature_t_top$PFAM_desc,annotated_cluster_feature_t_top$site_type))
  
  p = ggplot(top_feature_count,aes(x = Var1, y=Freq, fill=Var2))
  p = p + geom_bar(stat="identity") + theme_bw()
  p = p + labs(x = "Feature", y="Counts")
  p = p + theme(axis.title = element_text(size=12), axis.text.x = element_text(colour="black", size=10, angle = 90, vjust=0.5), axis.text.y = element_text(colour="black", size=12))#element_text(colour="black", size=14))
  p
  ggsave(file=paste("output/",type,"_top20_PFAM_features.pdf",sep=""), useDingbats=FALSE)
  
  top_gene_in_top_20_feature = names(table(annotated_cluster_feature_t_top$Gene_Drug)[order(table(annotated_cluster_feature_t_top$Gene_Drug),decreasing = T)][1:20])
  annotated_cluster_feature_t_top_topG = annotated_cluster_feature_t_top[annotated_cluster_feature_t_top$Gene_Drug %in% top_gene_in_top_20_feature,]
  top_feature_gene_count = data.frame(table(annotated_cluster_feature_t_top_topG$PFAM_desc,annotated_cluster_feature_t_top_topG$Gene_Drug,annotated_cluster_feature_t_top_topG$site_type))
  top_feature_gene_count$Freq_plot = top_feature_gene_count$Freq
  top_feature_gene_count$Freq_plot[top_feature_gene_count$Freq_plot>20]=20
  
  p = ggplot(top_feature_gene_count,aes(x = Var1, size=Freq_plot, y=Var2, color=Var1))
  p = p + facet_grid(.~Var3)
  p = p + geom_point(stroke = 0) + theme_bw() + scale_size_area()#range = c(0,10))
  p = p + labs(x = "Feature", y="Gene")
  p = p + geom_text(aes(label=ifelse(Freq > 10, Freq, NA)), color="black",size=3)
  p = p + theme(axis.title = element_text(size=12), axis.text.x = element_text(colour="black", size=10, angle = 90, vjust=0.5), axis.text.y = element_text(colour="black", size=12))#element_text(colour="black", size=14))
  p
  ggsave(file=paste("output/",type,"_top20_PFAM_features_20gene.pdf",sep=""), height=7, width=9, useDingbats=FALSE)
}

##### whether the domains are enriched in significant clusters #####
all_domains_test_enrich=vector("list")
k = 1
annotated_cluster_feature$hybrid=F
annotated_cluster_feature$hybrid[annotated_cluster_feature$Type=="Hybrid"]=T
#test_domain_scores = function(domain){
for (domain in (unique(annotated_cluster_feature$PFAM_desc))){
  #domain_name = annotated_cluster_feature$name[annotated_cluster_feature$domain==domain][1]
  if (sum(annotated_cluster_feature$PFAM_desc==domain, na.rm=T)<5){next}
  test.table = table(annotated_cluster_feature$PFAM_desc==domain,annotated_cluster_feature$hybrid)
  NotDomainNotHybrid = test.table[1,1]
  DomainNotHybrid = test.table[2,1]
  NotDomainHybrid = test.table[1,2]
  DomainHybrid = test.table[2,2]
  # fisher's exact test
  P = NA; OR = NA
  f.test = fisher.test(test.table,alternative ="greater")
  OR = f.test$estimate
  P = f.test$p.value
  
  row = c(domain, NotDomainNotHybrid, DomainNotHybrid, NotDomainHybrid, DomainHybrid, OR, P)
  all_domains_test_enrich[[k]] = row
  k = k + 1
}
all_domains_test_enrich_m = do.call(rbind,all_domains_test_enrich)
all_domains_test_enrich_m = data.frame(all_domains_test_enrich_m)
colnames(all_domains_test_enrich_m) = c("domain", "numSite_NotDomainNotHybrid", "numSite_DomainNotHybrid", "numSite_NotDomainHybrid", "numSite_DomainHybrid", "OR", "P")
for (i in 2:7){
  all_domains_test_enrich_m[,i] = as.numeric(as.character(all_domains_test_enrich_m[,i]))
}
all_domains_test_enrich_m$FDR=p.adjust(all_domains_test_enrich_m$P, method="BH")
all_domains_test_enrich_m = all_domains_test_enrich_m[order(as.numeric(as.character(all_domains_test_enrich_m$P)), decreasing=FALSE),]
tn = "output/hybrid_cluster_phosites_uniprot_domain_enrichment_fisher.tsv"
write.table(all_domains_test_enrich_m, file=tn, quote=F, sep = '\t', row.names=F)

top_feature = all_domains_test_enrich_m$domain[!is.na(all_domains_test_enrich_m$domain) & all_domains_test_enrich_m$domain != "N/A"][1:20]
all_domains_m_hybrid_uniprot_top = annotated_cluster_feature[annotated_cluster_feature$PFAM_desc %in% top_feature & annotated_cluster_feature$Type=="Hybrid",]

top_gene_in_top_feature = names(table(all_domains_m_hybrid_uniprot_top$Gene_Drug)[order(table(all_domains_m_hybrid_uniprot_top$Gene_Drug),decreasing = T)][1:20])
all_domains_m_hybrid_uniprot_top_topG = all_domains_m_hybrid_uniprot_top[all_domains_m_hybrid_uniprot_top$Gene_Drug %in% top_gene_in_top_feature,] #check vector etc
top_feature_gene_count_uniprot = data.frame(table(all_domains_m_hybrid_uniprot_top_topG$PFAM_desc,all_domains_m_hybrid_uniprot_top_topG$Gene_Drug,all_domains_m_hybrid_uniprot_top_topG$site_type))

top_feature_gene_count_uniprot$Freq_plot = top_feature_gene_count_uniprot$Freq
top_feature_gene_count_uniprot$Freq_plot[top_feature_gene_count_uniprot$Freq_plot>20]=20

#### show how many clusters they are from
gene_count = data.frame(table(all_domains_m_hybrid_uniprot_top_topG$Gene_Drug[!duplicated(paste(all_domains_m_hybrid_uniprot_top_topG$Gene_Drug,all_domains_m_hybrid_uniprot_top_topG$Cluster))]))
p = ggplot(gene_count,aes(x = Var1, y=Freq))
p = p + geom_bar(stat = "identity")
p = p + theme(axis.title = element_text(size=12), axis.text.x = element_text(colour="black", size=10, angle = 90, vjust=0.5), axis.text.y = element_text(colour="black", size=12))#element_text(colour="black", size=14))
p = p + theme(legend.position = "none") 
p = p + coord_flip() + theme_nogrid() + labs(x="Gene",y="Number of clusters in domains")
p
ggsave(file="output/top20sig_fisher_uniprot_domain_features_20_gene_gene_panel.pdf", h=4,w=3,useDingbats=FALSE)

p = ggplot(top_feature_gene_count_uniprot,aes(x = Var1, size=Freq_plot, y=Var2, color=Var1))
p = p + facet_grid(.~Var3)
p = p + geom_point(stroke = 0, alpha=0.7) + theme_bw() + scale_size_area()
p = p + labs(x = "Feature", y="Gene")
p = p + geom_text(aes(label=ifelse(Freq > 0, Freq, NA)), color="black",size=3)
p = p + theme(axis.title = element_text(size=12), axis.text.x = element_text(colour="black", size=10, angle = 90, vjust=0.5), axis.text.y = element_text(colour="black", size=12))#element_text(colour="black", size=14))
p = p + theme(legend.position = "none")
p
ggsave(file="output/top20sig_fisher_uniprot_domain_features_20_gene.pdf", h=7,w=8,useDingbats=FALSE)

getPalette = colorRampPalette(c("#FFFFFF","#fed976","#e31a1c"))
p = ggplot(top_feature_gene_count_uniprot,aes(x = Var1, fill=Freq_plot, y=Var2, color=Var1))
p = p + facet_grid(.~Var3)
p = p + geom_tile(linetype="blank")
p = p + geom_text(aes(label = ifelse(Freq!=0,Freq,NA)), color="black", size=2)
p = p + scale_fill_gradientn(name= "Count", colours=getPalette(100), na.value=NA, limit=c(0,NA))
p = p + labs(x = "Feature", y="Gene")
p = p + theme(axis.title = element_text(size=12), axis.text.x = element_text(colour="black", size=10, angle = 90, vjust=0.5), axis.text.y = element_text(colour="black", size=12))#element_text(colour="black", size=14))
p = p + theme(legend.position = "none")
p
ggsave(file="output/top20sig_fisher_uniprot_domain_features_20_gene_heatmap.pdf", h=7,w=8,useDingbats=FALSE)

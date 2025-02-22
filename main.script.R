preQC = function(samp.dat, anno.df, get.percent.mt = TRUE, qc.feature.list){
  
  # Create seurat project
  print("Creating Seurat Object")
  proj = CreateSeuratObject(counts = samp.dat, meta.data = anno.df)
  
  # Get mitochondrial percentage for QC
  if(get.percent.mt == TRUE){
    print("Getting QC metrics")
    proj[["percent.mt"]] = PercentageFeatureSet(proj, pattern = "MT^-")
    qc.feature.list = c(qc.feature.list, "percent.mt")
  }
  
  # Graph QC metrics
  print("Plotting QC metrics")
  qc.Plot = VlnPlot(proj, features = qc.feature.list)
  
  return(list(qc.Plot = qc.Plot, proj = proj)
}

## @ qc.param should be formatted as (param1 < num & param 2 > num & ...)
subsetCells = function(proj, qc.param){
  proj = subset(proj, subset = qc.param)
  
  return(proj)
}

## Normalize data, select features, scale, and linearly reduce
postQC = function(proj, selection.method, nfeatures){
  
  ## Normalize data
  print("Normalizing data")
  proj = NormalizeData(proj)
  
  ## Select features
  print("Selecting features")
  proj = FindVariableFeatures(proj, selection.method = selection.method,
                              nfeatures = nfeatures)
  
  ## Scale data
  print("Scaling data")
  all.genes = rownames(proj)
  proj = ScaleData(proj, features = all.genes)
  
  ## Run linear reduction (PCA)
  proj = runPCA(proj, features = VariableFeatures(object = proj))
  elbow = ElbowPlot(proj, ndims = 50)
  
  return(list(elbow = elbow, proj = proj))
}

## Cluster and find markers
clusterProj = function(proj, maxDim, resolution, topFeat){
  
  print("Clustering")
  proj = FindNeighbors(proj, dims = 1:maxDim)
  proj = FindClusters(proj, resolution = resolution)
  
  print("Running non-linear reduction")
  proj = RunUMAP(proj, dims = 1:maxDim)
  umap = DimPlot(proj, reduction = "umap", label = TRUE, raster = FALSE)
  
  print("Finding markers and features")
  marker.list = FindAllMarkers(proj, only.pos = TRUE)
  top.feature.list = marker.list %>% group_by(cluster) %>% 
    slice_max(n = topFeat, order_by = avg_log2FC)
  
  return(list(umap = umap, proj = proj, top.feature.list = top.feature.list))
}

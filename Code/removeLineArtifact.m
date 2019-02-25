function dataOut = removeLineArtifact(dataIn)
% function dataOut = removeLineArtifact(dataIn)
%
%--------------------------------------------------------------------------
% removeLineArtifact    removes artifacts that appear as lines of different 
%                       colours or intensities. The function uses filtering and 
%                       averaging of intensities.
%       INPUT
%         dataIn:           Image with the artifacts 
%
%
%       OUTPUT
%         dataOut:          The image without the artifacts
%
%--------------------------------------------------------------------------
%
%     Copyright (C) 2012  Constantino Carlos Reyes-Aldasoro
%
%     This file is part of the PhagoSight package.
%
%     The PhagoSight package is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, version 3 of the License.
%
%     The PhagoSight package is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with the PhagoSight package.  If not, see <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------
%
% This m-file is part of the PhagoSight package used to analyse fluorescent phagocytes
% as observed through confocal or multiphoton microscopes.  For a comprehensive 
% user manual, please visit:
%
%           http://www.phagosight.org.uk
%
% Please feel welcome to use, adapt or modify the files. If you can improve
% the performance of any other algorithm please contact us so that we can
% update the package accordingly.
%
% If you find this function useful leads to a publication, please cite as:
%
%    Henry KM, Pase L, Ramos-Lopez CF, Lieschke GJ, Renshaw SA,and Reyes-Aldasoro, CC
%    PhagoSight: An Open-Source MATLAB® Package for the Analysis of Fluorescent 
%    Neutrophil and Macrophage Migration in a Zebrafish Model
%   (2013) PLoS ONE 8(8): e72636. doi: 10.1371/journal.pone.0072636 
%
%--------------------------------------------------------------------------
%
% The authors shall not be liable for any errors or responsibility for the 
% accuracy, completeness, or usefulness of any information, or method in the content, or for any 
% actions taken in reliance thereon.
%
%--------------------------------------------------------------------------


%%
% Usual check of dimensions
[rows,cols,levs]=size(dataIn);

% Some tiff files have four levels, discard the fourth
if levs>3
    dataIn=(dataIn(:,:,1:3));
    levs=3;
end
%R=1:rows;
%C=1:cols;

%analyse per orientation, but only do it for the  central region, discard 5 lines/columns at the edges

data2= dataIn(7:end-6,7:end-6,:);

for k=1:levs
    % rows have to be split into odd and even frames
    rMeanData11 = (mean(data2(1:2:end,:,k),2));
    rMeanData12 = (mean(data2(2:2:end,:,k),2));

    rMeanData21 = diff(rMeanData11);
    rMeanData22 = diff(rMeanData12);

    %detect peaks at +-3std

    rPeaksLevel = 3*std([rMeanData21;rMeanData22]);

    rMeanData31 = rMeanData21.*((rMeanData21>rPeaksLevel)|(rMeanData21<-rPeaksLevel));
    rMeanData32 = rMeanData22.*((rMeanData22>rPeaksLevel)|(rMeanData22<-rPeaksLevel));


    %To correct the artifact down the rows, add inverted signal:


    rCorrFactor1= cumsum([zeros(4,1) ;rMeanData31;zeros(3,1)])*ones(1,cols);
    rCorrFactor2= cumsum([zeros(4,1) ;rMeanData32;zeros(3,1)])*ones(1,cols);


    dataOut(1:2:rows,:,k)   = (double(dataIn(1:2:end,:,k))-rCorrFactor1);
    dataOut(2:2:rows,:,k)   = (double(dataIn(2:2:end,:,k))-rCorrFactor2);
    %% now deal with the artefacts in the columns

    %cMeanData1 = (mean(data2(:,:,k),1));
    %cMeanData2 = diff(cMeanData1);


    %cPeaksLevel = 3*std(cMeanData2);
    %cMeanData3  = cMeanData2.*((cMeanData2>cPeaksLevel)|(cMeanData2<-cPeaksLevel));
    %cCorrFactor = ones(rows,1)*[zeros(1,6)  cMeanData3 zeros(1,7)];


    dataOutLPF = imfilter(dataOut(:,:,k),gaussF(2,5,1),'replicate');
    cMeanData1 = (mean(dataOut(:,:,k),1));
    cMeanData2 = (mean(dataOutLPF,1))-cMeanData1;


    cPeaksLevel = 3*std(cMeanData2);

    cMeanData3  = cMeanData2.*((cMeanData2>cPeaksLevel)|(cMeanData2<-cPeaksLevel));

    cCorrFactor = ones(rows,1)*cMeanData3;

    dataOut(:,:,k)          = dataOut(:,:,k)  + cCorrFactor;
    dataOut(:,:,k) = imfilter(dataOut(:,:,k),gaussF(3,3,1),'replicate');

end


dataOut(dataOut>255)=255;
dataOut(dataOut<0)=0;

 
if isa(dataIn,'uint8')
    dataOut=uint8(dataOut);
end


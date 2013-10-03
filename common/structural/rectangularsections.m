function RS = rectangularsections()
% Returns a list of common rectangular (and square) sections, as listed on
% page 181 of the RGB Stainless Stainless Steel Products Manual
%
% First column is the wall thickness of the section, second column is
% depth, or at least the larger dimension when the dimensions are
% different, and third column is width, the smaller dimension where
% applicable

RS = [1.000000,10.000000,10.000000;
    1.000000,12.000000,12.000000;
    1.000000,15.000000,15.000000;
    1.000000,16.000000,16.000000;
    1.000000,18.000000,18.000000;
    1.000000,20.000000,20.000000;
    1.000000,25.000000,25.000000;
    1.000000,30.000000,30.000000;
    1.000000,35.000000,35.000000;
    1.000000,40.000000,40.000000;
    1.000000,45.000000,45.000000;
    1.000000,50.000000,50.000000;
    1.200000,15.000000,15.000000;
    1.200000,16.000000,16.000000;
    1.200000,18.000000,18.000000;
    1.200000,20.000000,20.000000;
    1.200000,25.000000,25.000000;
    1.200000,30.000000,30.000000;
    1.200000,35.000000,35.000000;
    1.200000,40.000000,40.000000;
    1.200000,45.000000,45.000000;
    1.200000,50.000000,50.000000;
    1.500000,15.000000,15.000000;
    1.500000,16.000000,16.000000;
    1.500000,18.000000,18.000000;
    1.500000,20.000000,20.000000;
    1.500000,25.000000,25.000000;
    1.500000,30.000000,30.000000;
    1.500000,35.000000,35.000000;
    1.500000,40.000000,40.000000;
    1.500000,45.000000,45.000000;
    1.500000,50.000000,50.000000;
    1.500000,60.000000,60.000000;
    1.500000,80.000000,80.000000;
    1.500000,100.000000,100.000000;
    2.000000,16.000000,16.000000;
    2.000000,20.000000,20.000000;
    2.000000,25.000000,25.000000;
    2.000000,30.000000,30.000000;
    2.000000,35.000000,35.000000;
    2.000000,40.000000,40.000000;
    2.000000,45.000000,45.000000;
    2.000000,50.000000,50.000000;
    2.000000,60.000000,60.000000;
    2.000000,80.000000,80.000000;
    2.000000,100.000000,100.000000;
    2.000000,120.000000,120.000000;
    2.000000,150.000000,150.000000;
    2.000000,175.000000,175.000000;
    2.500000,25.000000,25.000000;
    2.500000,30.000000,30.000000;
    2.500000,35.000000,35.000000;
    2.500000,40.000000,40.000000;
    2.500000,45.000000,45.000000;
    2.500000,50.000000,50.000000;
    2.500000,60.000000,60.000000;
    2.500000,80.000000,80.000000;
    2.500000,100.000000,100.000000;
    3.000000,30.000000,30.000000;
    3.000000,35.000000,35.000000;
    3.000000,40.000000,40.000000;
    3.000000,45.000000,45.000000;
    3.000000,50.000000,50.000000;
    3.000000,60.000000,60.000000;
    3.000000,80.000000,80.000000;
    3.000000,100.000000,100.000000;
    4.000000,40.000000,40.000000;
    4.000000,45.000000,45.000000;
    4.000000,50.000000,50.000000;
    4.000000,60.000000,60.000000;
    4.000000,80.000000,80.000000;
    4.000000,100.000000,100.000000;
    4.000000,120.000000,120.000000;
    4.000000,150.000000,150.000000;
    4.000000,175.000000,175.000000;
    5.000000,60.000000,60.000000;
    5.000000,80.000000,80.000000;
    5.000000,100.000000,100.000000;
    5.000000,120.000000,120.000000;
    5.000000,150.000000,150.000000;
    5.000000,175.000000,175.000000;
    6.000000,100.000000,100.000000;
    6.000000,120.000000,120.000000;
    6.000000,150.000000,150.000000;
    6.000000,175.000000,175.000000;
    1.000000,20.000000,10.000000;
    1.000000,20.000000,15.000000;
    1.000000,25.000000,15.000000;
    1.000000,30.000000,10.000000;
    1.000000,30.000000,15.000000;
    1.000000,35.000000,15.000000;
    1.000000,35.000000,20.000000;
    1.000000,40.000000,15.000000;
    1.000000,40.000000,20.000000;
    1.000000,40.000000,30.000000;
    1.000000,50.000000,20.000000;
    1.000000,50.000000,30.000000;
    1.200000,20.000000,10.000000;
    1.200000,20.000000,15.000000;
    1.200000,25.000000,15.000000;
    1.200000,30.000000,10.000000;
    1.200000,30.000000,15.000000;
    1.200000,35.000000,15.000000;
    1.200000,35.000000,20.000000;
    1.200000,40.000000,15.000000;
    1.200000,40.000000,20.000000;
    1.200000,40.000000,30.000000;
    1.200000,50.000000,20.000000;
    1.200000,50.000000,25.000000;
    1.200000,50.000000,30.000000;
    1.200000,60.000000,20.000000;
    1.200000,60.000000,30.000000;
    1.200000,60.000000,40.000000;
    1.200000,70.000000,20.000000;
    1.200000,80.000000,40.000000;
    1.500000,20.000000,10.000000;
    1.500000,20.000000,15.000000;
    1.500000,25.000000,15.000000;
    1.500000,30.000000,10.000000;
    1.500000,30.000000,15.000000;
    1.500000,35.000000,15.000000;
    1.500000,35.000000,20.000000;
    1.500000,40.000000,15.000000;
    1.500000,40.000000,20.000000;
    1.500000,40.000000,30.000000;
    1.500000,50.000000,20.000000;
    1.500000,50.000000,25.000000;
    1.500000,50.000000,30.000000;
    1.500000,60.000000,20.000000;
    1.500000,60.000000,30.000000;
    1.500000,60.000000,40.000000;
    1.500000,70.000000,20.000000;
    1.500000,80.000000,40.000000;
    1.500000,80.000000,60.000000;
    1.500000,100.000000,40.000000;
    1.500000,100.000000,50.000000;
    1.500000,100.000000,60.000000;
    2.000000,25.000000,15.000000;
    2.000000,30.000000,15.000000;
    2.000000,35.000000,20.000000;
    2.000000,40.000000,15.000000;
    2.000000,40.000000,20.000000;
    2.000000,40.000000,30.000000;
    2.000000,50.000000,20.000000;
    2.000000,50.000000,25.000000;
    2.000000,50.000000,30.000000;
    2.000000,60.000000,20.000000;
    2.000000,60.000000,30.000000;
    2.000000,60.000000,40.000000;
    2.000000,70.000000,20.000000;
    2.000000,80.000000,40.000000;
    2.000000,80.000000,60.000000;
    2.000000,100.000000,40.000000;
    2.000000,100.000000,50.000000;
    2.000000,100.000000,60.000000;
    2.000000,100.000000,80.000000;
    2.000000,120.000000,60.000000;
    2.000000,120.000000,80.000000;
    2.000000,150.000000,50.000000;
    2.000000,200.000000,100.000000;
    2.000000,200.000000,150.000000;
    2.000000,250.000000,100.000000;
    2.500000,80.000000,40.000000;
    2.500000,80.000000,60.000000;
    2.500000,100.000000,40.000000;
    2.500000,100.000000,50.000000;
    3.000000,60.000000,30.000000;
    3.000000,60.000000,40.000000;
    3.000000,80.000000,40.000000;
    3.000000,80.000000,60.000000;
    3.000000,100.000000,40.000000;
    3.000000,100.000000,50.000000;
    3.000000,100.000000,60.000000;
    3.000000,100.000000,80.000000;
    3.000000,120.000000,60.000000;
    3.000000,120.000000,80.000000;
    3.000000,150.000000,50.000000;
    3.000000,200.000000,100.000000;
    3.000000,200.000000,150.000000;
    3.000000,250.000000,100.000000;
    4.000000,60.000000,40.000000;
    4.000000,80.000000,40.000000;
    4.000000,80.000000,60.000000;
    4.000000,100.000000,40.000000;
    4.000000,100.000000,50.000000;
    4.000000,100.000000,60.000000;
    4.000000,100.000000,80.000000;
    4.000000,120.000000,60.000000;
    4.000000,120.000000,80.000000;
    4.000000,150.000000,50.000000;
    4.000000,200.000000,100.000000;
    4.000000,200.000000,150.000000;
    4.000000,250.000000,100.000000;
    5.000000,100.000000,80.000000;
    5.000000,120.000000,60.000000;
    5.000000,120.000000,80.000000;
    5.000000,150.000000,50.000000;
    5.000000,200.000000,100.000000;
    5.000000,200.000000,150.000000;
    5.000000,250.000000,100.000000;
    6.000000,120.000000,60.000000;
    6.000000,120.000000,80.000000;
    6.000000,150.000000,50.000000;
    6.000000,200.000000,100.000000;
    6.000000,200.000000,150.000000;
    6.000000,250.000000,100.000000;
    1.000000,10.000000,20.000000;
    1.000000,15.000000,20.000000;
    1.000000,15.000000,25.000000;
    1.000000,10.000000,30.000000;
    1.000000,15.000000,30.000000;
    1.000000,15.000000,35.000000;
    1.000000,20.000000,35.000000;
    1.000000,15.000000,40.000000;
    1.000000,20.000000,40.000000;
    1.000000,30.000000,40.000000;
    1.000000,20.000000,50.000000;
    1.000000,30.000000,50.000000;
    1.200000,10.000000,20.000000;
    1.200000,15.000000,20.000000;
    1.200000,15.000000,25.000000;
    1.200000,10.000000,30.000000;
    1.200000,15.000000,30.000000;
    1.200000,15.000000,35.000000;
    1.200000,20.000000,35.000000;
    1.200000,15.000000,40.000000;
    1.200000,20.000000,40.000000;
    1.200000,30.000000,40.000000;
    1.200000,20.000000,50.000000;
    1.200000,25.000000,50.000000;
    1.200000,30.000000,50.000000;
    1.200000,20.000000,60.000000;
    1.200000,30.000000,60.000000;
    1.200000,40.000000,60.000000;
    1.200000,20.000000,70.000000;
    1.200000,40.000000,80.000000;
    1.500000,10.000000,20.000000;
    1.500000,15.000000,20.000000;
    1.500000,15.000000,25.000000;
    1.500000,10.000000,30.000000;
    1.500000,15.000000,30.000000;
    1.500000,15.000000,35.000000;
    1.500000,20.000000,35.000000;
    1.500000,15.000000,40.000000;
    1.500000,20.000000,40.000000;
    1.500000,30.000000,40.000000;
    1.500000,20.000000,50.000000;
    1.500000,25.000000,50.000000;
    1.500000,30.000000,50.000000;
    1.500000,20.000000,60.000000;
    1.500000,30.000000,60.000000;
    1.500000,40.000000,60.000000;
    1.500000,20.000000,70.000000;
    1.500000,40.000000,80.000000;
    1.500000,60.000000,80.000000;
    1.500000,40.000000,100.000000;
    1.500000,50.000000,100.000000;
    1.500000,60.000000,100.000000;
    2.000000,15.000000,25.000000;
    2.000000,15.000000,30.000000;
    2.000000,20.000000,35.000000;
    2.000000,15.000000,40.000000;
    2.000000,20.000000,40.000000;
    2.000000,30.000000,40.000000;
    2.000000,20.000000,50.000000;
    2.000000,25.000000,50.000000;
    2.000000,30.000000,50.000000;
    2.000000,20.000000,60.000000;
    2.000000,30.000000,60.000000;
    2.000000,40.000000,60.000000;
    2.000000,20.000000,70.000000;
    2.000000,40.000000,80.000000;
    2.000000,60.000000,80.000000;
    2.000000,40.000000,100.000000;
    2.000000,50.000000,100.000000;
    2.000000,60.000000,100.000000;
    2.000000,80.000000,100.000000;
    2.000000,60.000000,120.000000;
    2.000000,80.000000,120.000000;
    2.000000,50.000000,150.000000;
    2.000000,100.000000,200.000000;
    2.000000,150.000000,200.000000;
    2.000000,100.000000,250.000000;
    2.500000,40.000000,80.000000;
    2.500000,60.000000,80.000000;
    2.500000,40.000000,100.000000;
    2.500000,50.000000,100.000000;
    3.000000,30.000000,60.000000;
    3.000000,40.000000,60.000000;
    3.000000,40.000000,80.000000;
    3.000000,60.000000,80.000000;
    3.000000,40.000000,100.000000;
    3.000000,50.000000,100.000000;
    3.000000,60.000000,100.000000;
    3.000000,80.000000,100.000000;
    3.000000,60.000000,120.000000;
    3.000000,80.000000,120.000000;
    3.000000,50.000000,150.000000;
    3.000000,100.000000,200.000000;
    3.000000,150.000000,200.000000;
    3.000000,100.000000,250.000000;
    4.000000,40.000000,60.000000;
    4.000000,40.000000,80.000000;
    4.000000,60.000000,80.000000;
    4.000000,40.000000,100.000000;
    4.000000,50.000000,100.000000;
    4.000000,60.000000,100.000000;
    4.000000,80.000000,100.000000;
    4.000000,60.000000,120.000000;
    4.000000,80.000000,120.000000;
    4.000000,50.000000,150.000000;
    4.000000,100.000000,200.000000;
    4.000000,150.000000,200.000000;
    4.000000,100.000000,250.000000;
    5.000000,80.000000,100.000000;
    5.000000,60.000000,120.000000;
    5.000000,80.000000,120.000000;
    5.000000,50.000000,150.000000;
    5.000000,100.000000,200.000000;
    5.000000,150.000000,200.000000;
    5.000000,100.000000,250.000000;
    6.000000,60.000000,120.000000;
    6.000000,80.000000,120.000000;
    6.000000,50.000000,150.000000;
    6.000000,100.000000,200.000000;
    6.000000,150.000000,200.000000;
    6.000000,100.000000,250.000000];

end
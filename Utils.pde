color addColors(color a, color b){
  float re = red(a) + red(b);
  if(re>1) re = 1; else if(re<0) re = 0;
  float gr = green(a) + green(b);
  if(gr>1) gr = 1; else if(gr<0) gr = 0;
  float bl = blue(a) + blue(b);
  if(bl>1) bl = 1; else if(bl<0) bl = 0;
  return color(re,gr,bl);
}
color addColors(color a, color b, float coeff){
  float re = red(a) + coeff*red(b);
  if(re>1) re = 1; else if(re<0) re = 0;
  float gr = green(a) + coeff*green(b);
  if(gr>1) gr = 1; else if(gr<0) gr = 0;
  float bl = blue(a) + coeff*blue(b);
  if(bl>1) bl = 1; else if(bl<0) bl = 0;
  return color(re,gr,bl);
}
color avgColors(color a, color b, float fac){
  float re = red(a) + red(b);
  re = re/fac;
  if(re>1) re = 1; else if(re<0) re = 0;
  float gr = green(a) + green(b);
  gr = gr/fac;
  if(gr>1) gr = 1; else if(gr<0) gr = 0;
  float bl = blue(a) + blue(b);
  bl = bl/fac;
  if(bl>1) bl = 1; else if(bl<0) bl = 0;
  return color(re,gr,bl);
}
color mulColors(color a, color b){
  float re = red(a) * red(b);
  if(re>1) re = 1; else if(re<0) re = 0;
  float gr = green(a) * green(b);
  if(gr>1) gr = 1; else if(gr<0) gr = 0;
  float bl = blue(a) * blue(b);
  if(bl>1) bl = 1; else if(bl<0) bl = 0;
  return color(re,gr,bl);
}
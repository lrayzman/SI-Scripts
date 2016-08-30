//Graphical demonstration of the convolution process
// Demonstrates some control aspects of 2D plots
//

stacksize(64*1024*1024);
 
deff('x=xoft(t)','x=1.5*sin(%pi*t).*(t>=0&t<1)') //input signal
  
deff('h=hoft(t)','h=1.5*(t>=0&t<1.5)-(t>=2&t<2.5)') //impulse response
  
dtau=0.005;
tau = -1:dtau:4;

ti=0;
tvec = -0.25:.1:3.75;
y=%nan*zeros(1, length(tvec));

//initialize plot windows
curFig = scf(0);
clf(curFig,"reset");
subplot(2,1,1);
mtlb_axis([tau(1) tau($) -2.0 2.5]);
xlabel('t');
ylabel('x(t) and h(t)');
set(gca(),"grid",[1 1])
subplot(2,1,2);
mtlb_axis([tau(1) tau($) -1.0 2.0]); 
xlabel('t');
ylabel('y(t)=x(t) * h(t)');
set(gca(),"grid",[1 1]);


realtimeinit(0.5);  //

for t=tvec,
    ti = ti+1;
    realtime(ti);
     xh = xoft(t-tau).*hoft(tau);
      y(ti) = sum(xh.*dtau);
      drawlater;
      subplot(2,1,1);
      if ti > 1 then
        f=get("current_figure");
        a=f.children;
        c=a.children;
        delete(c);
      end;
      plot(tau, xh, '12', tau, xoft(t-tau), 'b-', tau, hoft(tau),'k-');
      a=get("current_axes");
      c=a.children;
      p=c.children(3);
      p.polyline_style=5;
      p.foreground=12;
      subplot(2,1,2)
      plot(tvec,y,'k',tvec(ti),y(ti),'ok');
      drawnow;
end

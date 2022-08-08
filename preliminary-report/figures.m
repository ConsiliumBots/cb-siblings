%% Set Paths
username = 'antoniaaguilera';
if strcmp(username,'antoniaaguilera')
    Path = '/Users/antoniaaguilera/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/';
    dataPath = [Path 'data/'];
    figuresPath = [ Path 'figures/'];
else
    error('Get your paths straight!')
end

%% Call Data
q4    = xlsread([ dataPath 'intermediate/survey/q4.xlsx']);
q10   = xlsread([ dataPath 'intermediate/survey/q10.xlsx']);
q11   = xlsread([ dataPath 'intermediate/survey/q11.xlsx']);
q12   = xlsread([ dataPath 'intermediate/survey/q12.xlsx']);
q13   = xlsread([ dataPath 'intermediate/survey/q13.xlsx']);
q14   = xlsread([ dataPath 'intermediate/survey/q14_2.xlsx']);
q15   = xlsread([ dataPath 'intermediate/survey/q15.xlsx']);
q15_1 = xlsread([ dataPath 'intermediate/survey/q15_1.xlsx']);
q16   = xlsread([ dataPath 'intermediate/survey/q16.xlsx']);

%% Set Colors
c = parula(63);

%% Q4
x   = [1 2 3 4 5] ;
tot = sum(q4(:,1));
pc  = q4(:,1)/tot*100;
str = ['N: ', num2str(tot)];

close
figure(1)
[s,r] = sort(pc);
barh(x, pc(r), "LineWidth",1,"FaceColor",c(10,:),"EdgeColor","none","FaceAlpha",0.8)
yticklabels(["Menor en 2º y mayor en 1º","Otro","Menor en 1º y mayor en 2º","Ambos en 2º", "Ambos en 1º"])
xlabel("Porcentaje (%)")
title("Preferencias sobre Asignación de Hijos")
grid
text(80, 5.8, str)
saveas(gcf,[figuresPath 'q4.png'])

%% Q10
x = [1 2 3 4 5] ;
y = [85.87 11.31 1.41 1.06 0.35; 2.12  4.95  41.34 42.05 9.54; 0.71 5.65 21.55 51.59 20.14; 10.95 76.68 7.07 4.95 0.35; 1.06 28.62 0.35 69.61 0.35] ;
tot=sum(q10(:,2));
str = ['N: ', num2str(tot)];

close
figure(2)
b = barh(x,y,'stacked');
set(b(1),"FaceColor",c(10,:), "FaceAlpha", 0.8)
set(b(2),"FaceColor",c(20,:), "FaceAlpha", 0.8)
set(b(3),"FaceColor",c(30,:), "FaceAlpha", 0.8)
set(b(4),"FaceColor",c(40,:), "FaceAlpha", 0.8)
set(b(5),"FaceColor",c(50,:), "FaceAlpha", 0.8)
xlim([0, 100])
text(80, 5.8, str)
yticklabels(["1º preferencia", "2º preferencia", "3º preferencia", "4º preferencia", "5º preferencia"]);
title("Preferencias de Asignación")
legend("Ambos en 1º", "Menor en 1º y Mayor en 2º", "Mayor en 2º y Menor en 1º", "Ambos en 2º", "Ninguno es admitido", "Location","southoutside", "NumColumns", 5)
grid
saveas(gcf,[figuresPath 'q10.png'])

%% Q11
tot=q11(1,3);
str = ['N: ', num2str(tot)];
x = [1, 2, 3, 4] ; 
%pc = q11(:,1)

close
figure(3)
%[s,r] = sort(pc);
barh(x, q11(:,1), "LineWidth",1,"FaceColor",c(10,:),"EdgeColor","none","FaceAlpha",0.8)
title("Probabilidad de rechazar la vacante")
subtitle("Cuando ambos hijos no son admitidos en la misma escuela")
xlabel("Proporción")
grid
text(0.35,4.7, str)
yticklabels(["0%","1-10%","50%","100%" ])
saveas(gcf,[figuresPath 'q11.png'])

%% Q12
tot = q12(1,11);
str = ['N: ', num2str(tot)];
x = [1 2 3 4 5] ;
d = parula(100);
y = [q12(1,1) q12(2,1) q12(3,1) q12(4,1) q12(5,1) q12(6,1) q12(7,1) q12(8,1) q12(9,1) q12(10,1); q12(1,2) q12(2,2) q12(3,2) q12(4,2) q12(5,2) q12(6,2) q12(7,2) q12(8,2) q12(9,2) q12(10,2); q12(1,3) q12(2,3) q12(3,3) q12(4,3) q12(5,3) q12(6,3) q12(7,3) q12(8,3) q12(9,3) q12(10,3); q12(1,4) q12(2,4) q12(3,4) q12(4,4) q12(5,4) q12(6,4) q12(7,4) q12(8,4) q12(9,4) q12(10,4); q12(1,5) q12(2,5) q12(3,5) q12(4,5) q12(5,5) q12(6,5) q12(7,5) q12(8,5) q12(9,5) q12(10,5)] ;

close
figure(4)
b = barh(x,y,'stacked');
set(b(1),"FaceColor",d(10,:), "FaceAlpha", 0.8)
set(b(2),"FaceColor",d(20,:), "FaceAlpha", 0.8)
set(b(3),"FaceColor",d(30,:), "FaceAlpha", 0.8)
set(b(4),"FaceColor",d(40,:), "FaceAlpha", 0.8)
set(b(5),"FaceColor",d(50,:), "FaceAlpha", 0.8)
set(b(6),"FaceColor",d(60,:), "FaceAlpha", 0.8)
set(b(7),"FaceColor",d(70,:), "FaceAlpha", 0.8)
set(b(8),"FaceColor",d(80,:), "FaceAlpha", 0.8)
set(b(9),"FaceColor",d(90,:), "FaceAlpha", 0.8)
set(b(10),"FaceColor",d(100,:), "FaceAlpha", 0.8)
title("Creencia en la probabilidad de Asignación")
yticklabels(["Ambos en 1º", "Menor en 1º y Mayor en 2º", "Mayor en 2º y Menor en 1º", "Ambos en 2º", "Ninguno es admitido"])
legend("0-10%","11-20%", "21-30%", "31-40%", "41-50%","51-60%","61-70%","71-80%","81-90%" ,"91-100%", "Location","southoutside", "NumColumns", 5)
xlabel("Probabilidad (%)")
xlim([0,1])
grid
text(0.9,5.7,str)
saveas(gcf,[figuresPath 'q12.png'])

%% Q13
tot = q13(1,2);
str = ['N: ', num2str(tot)];
close 
figure(5)
x = [1, 2];
b = bar(x,q13(:,3),'stacked');
set(b(1),"FaceColor",c(10,:), "FaceAlpha", 0.8)
xticklabels(["No", "Si"]);
title("¿Sabe qué pasa cuándo usted marca postulación familiar?")
ylabel("Porcentaje (%)")
grid
text(2.5,55,str)
saveas(gcf,[figuresPath 'q13.png'])

%% Q14 
x = [1, 2, 3, 4, 5, 6] ;
figure(6) ;
y = q14(:,3) ;
tot=q14(1,2);
str = ['N: ', num2str(tot)];

[s,r] = sort(y);
barh(x, y(r), "LineWidth",1,"FaceColor",c(10,:),"EdgeColor","none","FaceAlpha",0.8)
yticklabels(["No se", "Todos o ninguno", "Hermano arrastra automáticamente al otro","Postular a más de un niño","Preferencia Hermano", "Preferencia a que hijos queden juntos"])
xlabel("Porcentaje (%)")
title("Creencias sobre postulación familiar")
grid
text(53, 6.8, str)
saveas(gcf,[figuresPath 'q14.png'])


%% Q15
tot = q15(1,2);
str = ['N: ', num2str(tot)];
close 
figure(7)
x = [1, 2];
b = bar(x, q15(:,3),'stacked');
set(b(1),"FaceColor",c(10,:), "FaceAlpha", 0.8)
xticklabels(["No se", "Si"]);
title("¿Le gustaría que el SAE evaluara sus postulaciones de forma conjunta?")
ylabel("Porcentaje (%)")
grid
text(2.7,80,str)
saveas(gcf,[figuresPath 'q15.png'])

%% Q15_1
tot = q15_1(1,3);
str = ['N: ', num2str(tot)];

close
figure(8)
s = bar(q15_1(:,1), q15_1(:,4)) ;
set(s(1),"FaceColor",c(10,:), "FaceAlpha", 0.8)
title("Creencia en la probabilidad de asignación del hijo mayor")
subtitle("Cuando postula al año siguiente a la misma escuela que hijo menor")
xlabel("Probabilidad de postular (%)")
ylabel("Proporción")
xticklabels(["0-10%","11-20%","21-30%","31-40%","41-50%","51-60%","61-70%","71-80%","81-90%","91-100%"])
grid
text(100,0.28,str)
saveas(gcf,[figuresPath 'q15_1.png'])

%% Q16
tot = q16(1,2);
str = ['N: ', num2str(tot)];
close 
figure(9)
x = [1, 2];
b = bar(x, q16(:,3),'stacked');
set(b(1),"FaceColor",c(10,:), "FaceAlpha", 0.8)
xticklabels(["No", "Si"]);
title("¿Ya había visto sus resultados de la asignación SAE al momento de la encuesta?")
ylabel("Porcentaje (%)")
grid
text(2.7,75,str)
saveas(gcf,[figuresPath 'q16.png'])


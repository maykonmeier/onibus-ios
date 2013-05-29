//
//  DetalhesDoOnibusController.m
//  BusaoSP
//
//  Created by Erich Egert on 5/24/13.
//  Copyright (c) 2013 None. All rights reserved.
//

#import "DetalhesDoOnibusController.h"
#import "UILabel+DetailLabel.h"
#import "MKMapView+ZoomOut.h"
#import "Parada.h"
#import "AnnotationViewFactory.h"
#import "Veiculo.h"



@interface DetalhesDoOnibusController ()

@property(nonatomic, strong) MKMapView* mapView;

@property(nonatomic, weak) NSArray* onibuses;
@property(nonatomic, strong) Localizacao *localizacao;
@property(nonatomic, strong) ParadaDataSource *paradasDataSource;
@property(nonatomic, strong) NSMutableArray *tempoRealDatasources;

@property(nonatomic, strong) NSArray *imagemsVeiculos;
@property(nonatomic, strong) UIImage *imagemParada;

@end

@implementation DetalhesDoOnibusController

- (id)initWithOnibuses: (NSArray*) onibuses andLocalizacao: (Localizacao*) localizacao
{
    self = [super init];
    if (self) {
        self.mapView = [[MKMapView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
        self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.onibuses = onibuses;
        self.localizacao = localizacao;
        
        self.imagemsVeiculos = @[
                                 [UIImage imageNamed:@"pin-bus-green.png"],
                                 [UIImage imageNamed:@"pin-bus-orange.png"],
                                 [UIImage imageNamed:@"pin-bus-red.png"]
                                ];
        self.imagemParada = [UIImage imageNamed:@"pin-busstop-transp.png"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.view = self.mapView;
    self.tempoRealDatasources = [[NSMutableArray alloc] init];
    self.title = @"Tempo real";
    
    MKUserTrackingBarButtonItem *buttonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    self.navigationItem.rightBarButtonItem = buttonItem;

    
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    CGRect rectFundo = CGRectMake(0, 0, frame.size.width, 30);
    UIView *fundo = [[UIView alloc] initWithFrame:rectFundo];
    fundo.backgroundColor = [UIColor colorWithRed:0.0 green:0.1 blue:0.1 alpha:0.75];
    [self.view addSubview:fundo];
    
    for (int i=0; i< [self.onibuses count]; i++) {
        Onibus *onibus = [self.onibuses objectAtIndex:i];
        UIImage *imagem = [self.imagemsVeiculos objectAtIndex:i];
        
        int larguraImagem = imagem.size.width;
        int larguraLabel = 70;
        int larguraEntreImagemELabel = 5;
        int larguraTotal = larguraEntreImagemELabel + larguraLabel + larguraImagem;
        
        UILabel *label = [UILabel labelWithText:onibus.letreiro andStartingAtX:imagem.size.width+5+(i*larguraTotal) andY:0];
        label.backgroundColor = [UIColor colorWithRed:0.0 green:0.1 blue:0.1 alpha:0.0];
        

        UIImageView *imageView = [[UIImageView alloc] initWithFrame: CGRectMake(5+i*larguraTotal, 0, imagem.size.width, imagem.size.height)];
        [imageView setImage:imagem];
        [self.view addSubview:imageView];
        
        [self.view addSubview:label];
    }
    
    [self buscaDetalhesDoOnibus];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    MKAnnotationView *annotationView = [AnnotationViewFactory createViewForAnnotation:annotation inMapView:self.mapView];
    
    if([annotation isKindOfClass:[Parada class]]){
        annotationView.image = self.imagemParada;
    }
    
    if([annotation isKindOfClass:[Veiculo class]]){
        Veiculo *veiculo = (Veiculo*) annotation;
        annotationView.image = [self.imagemsVeiculos objectAtIndex:veiculo.onibus];
    }

    
    return annotationView;
}

- (void)buscaDetalhesDoOnibus {
    
    
    for (Onibus *onibus in self.onibuses) {
        TempoRealDataSource *tempoRealDataSource = [[TempoRealDataSource alloc] initWithDelegate:self];
        [tempoRealDataSource buscaLocalizacoesParaOnibus: onibus];
        [self.tempoRealDatasources addObject:tempoRealDataSource];
    }
    
    if ([self.onibuses count] == 1) {
        Onibus *onibus = [self.onibuses objectAtIndex:0];
        self.paradasDataSource = [[ParadaDataSource alloc] initWithDelegate:self];
        [self.paradasDataSource buscaParadasParaOnibus:onibus];
    }
    
}

- (BOOL)mesmaParadaParaLocalizacao: (Parada *) parada {
    return [self.localizacao isEqual:parada.localizacao];
}

- (void) recebeParadas: (NSArray *) paradas paraOnibus: (Onibus *) onibus {
    [self.mapView addAnnotations:paradas];
    [self.mapView zoomOut];
    
}
- (void) problemaParaBuscarParadas {
    //TODO
}

-(void) problemaParaBuscarLocalizacoes {
    //TODO
}

- (void) recebeLocalizacoes: (NSArray *) localizacoes paraOnibus: (Onibus *) onibus {
    NSLog(@"Recebendo locais do onibus: %@ ---> %@", onibus, localizacoes);
    
    if ([localizacoes count] > 0) {
        for (Veiculo *veiculo in localizacoes) {
            veiculo.onibus = [self.onibuses indexOfObject:onibus];
            [self.mapView addAnnotation:veiculo];
        }
        [self.mapView zoomOut];
        
    } else {
        NSString *mensagem = [NSString stringWithFormat:@"Nenhum veiculo da linha %@ localizado no momento", [onibus letreiro]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tempo real"
                                                        message:mensagem
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

@end
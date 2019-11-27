package de.rhaudi.transfactclient.clients.printer;


import de.rhaudi.transfactclient.ContextProvider;
import de.rhaudi.transfactclient.Session;
import de.rhaudi.transfactclient.clientModel.Client;
import de.rhaudi.transfactclient.clientModel.ClientType;
import de.rhaudi.transfactclient.configuration.ClientConfigurations;


import java.util.concurrent.TimeUnit;

import de.rhaudi.common.TransfactModelDetail;
import de.rhaudi.common.TransfactModelLoader;
import de.rhaudi.entities.arbeitsschritte.ArbeitsschritteEntity;
import de.rhaudi.entities.arbeitsschritte.Arbeitsschritte;
import de.rhaudi.entities.vwcheckliste.VwChecklisteEntity;
import de.rhaudi.transfact.ValueLosstatus;
import de.rhaudi.transfact.ValueProperties;
import de.rhaudi.transfactclient.clients.printer.model.Assignment;
import de.rhaudi.transfactclient.clients.printer.model.AssignmentDetail;
import de.rhaudi.transfactclient.clients.printer.model.PrintDetails;

import java.net.*;
import java.io.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class Printer extends Client {

    private PrinterService printerService = ContextProvider.getBean(PrinterService.class);

    public Printer() {
        Init();
    }

    private void Init() {
        //this.setClientConfiguration(Session.getInstance().getClientConfigurations().getClientConfigByType(ClientType.printer));
        printerService.setClient(this);
        System.out.println("Init 3DDrucker");

        ArbeitsschritteEntity vorgang;
        TransfactModelDetail transfactModel;

        Socket socket1 = null;
        Socket socket2 = null;
        ServerSocket server = null;
        DataInputStream in = null;
        DataOutputStream out = null;
        String line = "";

       try {
            System.out.println("Setup Connection 1: CobotUR5 --> 3DDrucker");
            server = new ServerSocket(6009);
            System.out.println("3DDrucker Server started\nWaiting for CobotUR5 Client");
            socket1 = server.accept();
            System.out.println("CobotUR5 Client accepted");

            System.out.println("Setup Connection 2: 3DDrucker --> CobotUR5");
            do {
                try {
                    socket2 = new Socket("192.168.0.102", 5001);
                } catch (IOException i) {
                    System.out.println(i);
                }
            } while (socket2 == null);
            System.out.println("Connected to CobotUR5 Server");

            in = new DataInputStream(new BufferedInputStream(socket1.getInputStream()));
            out = new DataOutputStream(socket2.getOutputStream());
            while (true) {
                line = in.readUTF();
                if(line.equals("printer_start")) {
                    this.setClientConfiguration(Session.getInstance().getClientConfigurations().getClientConfigByType(ClientType.printer));
                    transfactModel = printerService.loadVorgang(ValueProperties.AKZ_VK_Drucken, ValueProperties.AKZ_VK_3DDrucker);
                    vorgang = transfactModel.logInNextArbeitsschritt(ValueProperties.AKZ_VK_3DDrucker);

                    //Map<ArbeitsschritteEntity, List<VwChecklisteEntity>> map = transfactModel.getArbeitsschritteEntityListMap();
				
                    long chargeId = transfactModel.getChargenEntity().getChId();
                    System.out.println("The chargeId to be parsed is "+chargeId);
                     
                    long chId = Long.valueOf(chargeId);

                    PrintDetails printDetails = new PrintDetails();


                    TransfactModelDetail transfactModelDetail = TransfactModelLoader.getTransModelDetail(chId, ValueProperties.KS_3D_DRUCKER);
                    Map<ArbeitsschritteEntity, List<VwChecklisteEntity>> map = transfactModelDetail.getArbeitsschritteEntityListMap();

					for (Map.Entry<ArbeitsschritteEntity, List<VwChecklisteEntity>> entry : map.entrySet()) {
						if (entry.getValue().size() > 2) {
							for (VwChecklisteEntity vwChecklisteEntity : entry.getValue()) {
								if (vwChecklisteEntity.getCwTyp().equals("Nachname")) {
									if (vwChecklisteEntity.getCwCwValue() == null) {
										printDetails.setLastName(" ");
									} else {
										printDetails.setLastName(vwChecklisteEntity.getCwCwValue());
									}
								}
								if (vwChecklisteEntity.getCwTyp().equals("Vorname")) {
									if (vwChecklisteEntity.getCwCwValue() == null) {
										printDetails.setFirstName(" ");
									} else {
										printDetails.setFirstName(vwChecklisteEntity.getCwCwValue());
									}
								}
								if (vwChecklisteEntity.getCwTyp().equals("Logo")) {

									if (vwChecklisteEntity.getCwCwValue() == null) {
										printDetails.setLogo(" ");
									} else {
										printDetails.setLogo(vwChecklisteEntity.getCwCwValue());
									}
								}
								if (vwChecklisteEntity.getCwTyp().equals("Drucktext_Straße")) {

									if (vwChecklisteEntity.getCwCwValue() == null) {
										printDetails.setStreet(" ");
									} else {
										printDetails.setStreet(vwChecklisteEntity.getCwCwValue());
									}
								}
								if (vwChecklisteEntity.getCwTyp().equals("Drucktext_Ort")) {

									if (vwChecklisteEntity.getCwCwValue() == null) {
										printDetails.setCity(" ");
									} else {
										printDetails.setCity(vwChecklisteEntity.getCwCwValue());
									}
								}
								if (vwChecklisteEntity.getCwTyp().equals("Drucktext_Land")) {

									if (vwChecklisteEntity.getCwCwValue() == null) {
										printDetails.setCountry(" ");
									} else {
										printDetails.setCountry(vwChecklisteEntity.getCwCwValue());
									}
								}
								printDetails.setName(printDetails.getFirstName() + " " + printDetails.getLastName());
							}
						}
					}


                     System.out.println("Name: " + printDetails.getName());
                     System.out.println("Steet: " + printDetails.getStreet());
                     System.out.println("City: " + printDetails.getCity());
                     System.out.println("Country: " + printDetails.getCountry());
                     System.out.println("Logo: " + printDetails.getLogo());
                     System.out.println("SerialNumber: " + chargeId); 
	
		    //printerService.executeScript(chId);
					
		    //Wait till 3DDrucker prints the plate
		    vorgang = transfactModel.logOutNextArbeitsschritt(ValueProperties.AKZ_VK_3DDrucker);

                    out.writeUTF("printer_finish");
                    line = "";
                } else if(line.equals("printer_response")) {
                    out.writeUTF("cobot_response");
                    line = "";
                }
            }

            //socket1.close();
            //socket2.close();
            //in.close();
            //out.close();
	} catch (UnknownHostException u) {
            System.out.println(u);
        } catch (IOException i) {
            System.out.println(i);
        }

    }


}


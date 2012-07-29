#GIO is the reference Mission customization used for tests
BEGIN{ 
    use FindBin qw($Bin);
    require "$Bin/Custo-gio.pm" 
}

package ref1;

our $tmp ="0904C182002C10031900000000931AE4060000000000000000003C0B81003CA18E0000000000000000003C0B81003CA18E4FE6";
our $r_tmp = {
          'Packet Header' => {
                               'Packet Sequence Control' => {
                                                              'Source Seq Count' => 386,
                                                              'Packet Length' => 44,
                                                              'Segmentation Flags' => 3
                                                            },
                               'Packet Id' => {
                                                'vApid' => 260,
                                                'DFH Flag' => 1,
                                                'Type' => 0,
                                                'Version Number' => 0,
                                                'Apid' => {
                                                            'PID' => 16,
                                                            'Pcat' => 4
                                                          }
                                              }
                             },
          'Has Crc' => 1,
          'Packet Data Field' => {
                                   'Packet Error Control' => 20454,
                                   'TMSourceSecondaryHeader' => {
                                                                  'Length' => 10,
                                                                  'Sat_Time' => {
                                                                                  'CUC Fine' => [
                                                                                                  26,
                                                                                                  228
                                                                                                ],
                                                                                  'CUC Coarse' => [
                                                                                                    0,
                                                                                                    0,
                                                                                                    0,
                                                                                                    147
                                                                                                  ],
                                                                                  'OBT' => '147.105041503906'
                                                                                },
                                                                  'Destination Id' => 0,
                                                                  'Service Subtype' => 25,
                                                                  'Service Type' => 3,
                                                                  'SecHeadFirstField' => {
                                                                                           'Spare1' => 0,
                                                                                           'Spare2' => 0,
                                                                                           'PUS Version Number' => 1
                                                                                         }
                                                                },
                                   'Source Data' => [
                                                      6,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      60,
                                                      11,
                                                      129,
                                                      0,
                                                      60,
                                                      161,
                                                      142,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      0,
                                                      60,
                                                      11,
                                                      129,
                                                      0,
                                                      60,
                                                      161,
                                                      142
                                                    ]
                                 }
        };

our $r_tmph= {
          'Packet Sequence Control' => {
                                         'Source Seq Count' => 386,
                                         'Packet Length' => 44,
                                         'Segmentation Flags' => 3
                                       },
          'Packet Id' => {
                           'vApid' => 260,
                           'DFH Flag' => 1,
                           'Type' => 0,
                           'Version Number' => 0,
                           'Apid' => { 
                               'PID' => 16, 
                               'Pcat' => 4 
                                     }
                         }
        };

public class AddressStandardization {
    
    public static final Map<String, String> ISOCodeToCountryName = new Map<String, String>{
        'AF'=>'Afghanistan',
        'AX'=>'Åland Islands',
        'AL'=>'Albania',
        'DZ'=>'Algeria',
        'AS'=>'American Samoa',
        'AD'=>'Andorra',
        'AO'=>'Angola',
        'AI'=>'Anguilla',
        'AQ'=>'Antarctica',
        'AG'=>'Antigua and Barbuda',
        'AR'=>'Argentina',
        'AM'=>'Armenia',
        'AW'=>'Aruba',
        'AU'=>'Australia',
        'AUS'=>'Australia',
        'AT'=>'Austria',
        'AZ'=>'Azerbaijan',
        'BS'=>'Bahamas',
        'BH'=>'Bahrain',
        'BD'=>'Bangladesh',
        'BB'=>'Barbados',
        'BY'=>'Belarus',
        'BE'=>'Belgium',
        'BZ'=>'Belize',
        'BJ'=>'Benin',
        'BM'=>'Bermuda',
        'BT'=>'Bhutan',
        'BO'=>'Bolivia',
        'BQ'=>'Caribbean Netherlands Bonai',
        'BA'=>'Bosnia and Herzegovina',
        'BW'=>'Botswana',
        'BV'=>'Bouvet Island',
        'BR'=>'Brazil',
        'IO'=>'British Indian Ocean Territory',
        'BN'=>'Brunei',
        'BG'=>'Bulgaria',
        'BF'=>'Burkina Faso',
        'BI'=>'Burundi',
        'CV'=>'Cape Verde',
        'KH'=>'Cambodia',
        'CM'=>'Cameroon',
        'CA'=>'Canada',
        'CAN'=>'Canada',
        'KY'=>'Cayman Islands',
        'CF'=>'Central African Republic',
        'TD'=>'Chad',
        'CL'=>'Chile',
        'CN'=>'China',
        'CX'=>'Christmas Island',
        'CC'=>'Cocos (Keeling) Islands',
        'CO'=>'Colombia',
        'KM'=>'Comoros',
        'CG'=>'Congo',
        'CD'=>'Democratic Republic of the Congo',
        'CK'=>'Cook Islands',
        'CR'=>'Costa Rica',
        'CI'=>'Ivory Coast',
        'HR'=>'Croatia',
        'CU'=>'Cuba',
        'CW'=>'Curaçao',
        'CY'=>'Cyprus',
        'CZ'=>'Czech Republic',
        'DK'=>'Denmark',
        'DJ'=>'Djibouti',
        'DM'=>'Dominica',
        'DO'=>'Dominican Republic',
        'EC'=>'Ecuador',
        'EG'=>'Egypt',
        'SV'=>'El Salvador',
        'GQ'=>'Equatorial Guinea',
        'ER'=>'Eritrea',
        'EE'=>'Estonia',
        'SZ'=>'Eswatini',
        'ET'=>'Ethiopia',
        'FK'=>'Falkland Islands (Malvinas)',
        'FO'=>'Faroe Islands',
        'FJ'=>'Fiji',
        'FI'=>'Finland',
        'FR'=>'France',
        'GF'=>'French Guiana',
        'PF'=>'French Polynesia',
        'TF'=>'French Southern Territories',
        'GA'=>'Gabon',
        'GE'=>'Georgia',
        'DE'=>'Germany',
        'GH'=>'Ghana',
        'GM'=>'Gambia',
        'GI'=>'Gibraltar',
        'GR'=>'Greece',
        'GL'=>'Greenland',
        'GD'=>'Grenada',
        'GP'=>'Guadeloupe',
        'GU'=>'Guam',
        'GT'=>'Guatemala',
        'GG'=>'Guernsey',
        'GN'=>'Guinea',
        'GW'=>'Guinea-Bissau',
        'GY'=>'Guyana',
        'HT'=>'Haiti',
        'HM'=>'Heard Island and McDonald Islands',
        'VA'=>'Holy See (Vatican City State)',
        'HN'=>'Honduras',
        'HK'=>'Hong Kong',
        'HU'=>'Hungary',
        'IS'=>'Iceland',
        'IN'=>'India',
        'ID'=>'Indonesia',
        'IR'=>'Iran',
        'IQ'=>'Iraq',
        'IE'=>'Ireland',
        'IM'=>'Isle of Man',
        'IL'=>'Israel',
        'IT'=>'Italy',
        'JM'=>'Jamaica',
        'JP'=>'Japan',
        'JE'=>'Jersey',
        'JO'=>'Jordan',
        'KZ'=>'Kazakhstan',
        'KE'=>'Kenya',
        'KI'=>'Kiribati',
        'KP'=>'North Korea',
        'KR'=>'South Korea',
        'KW'=>'Kuwait',
        'KG'=>'Kyrgyzstan',
        'LA'=>'Laos',
        'LV'=>'Latvia',
        'LB'=>'Lebanon',
        'LS'=>'Lesotho',
        'LR'=>'Liberia',
        'LY'=>'Libya',
        'LI'=>'Liechtenstein',
        'LT'=>'Lithuania',
        'LU'=>'Luxembourg',
        'MO'=>'Macau',
        'MG'=>'Madagascar',
        'MW'=>'Malawi',
        'MY'=>'Malaysia',
        'MV'=>'Maldives',
        'ML'=>'Mali',
        'MT'=>'Malta',
        'MH'=>'Marshall Islands',
        'MQ'=>'Martinique',
        'MR'=>'Mauritania',
        'MU'=>'Mauritius',
        'YT'=>'Mayotte',
        'MX'=>'Mexico',
        'FM'=>'Federated States of Micronesia',
        'MD'=>'Moldova',
        'MC'=>'Monaco',
        'MN'=>'Mongolia',
        'ME'=>'Montenegro',
        'MS'=>'Montserrat',
        'MA'=>'Morocco',
        'MZ'=>'Mozambique',
        'MM'=>'Myanmar',
        'NA'=>'Namibia',
        'NR'=>'Nauru',
        'NP'=>'Nepal',
        'NL'=>'Netherlands',
        'The Netherlands' => 'Netherlands',
        'NC'=>'New Caledonia',
        'NZ'=>'New Zealand',
        'NI'=>'Nicaragua',
        'NE'=>'Niger',
        'NG'=>'Nigeria',
        'NU'=>'Niue',
        'NF'=>'Norfolk Island',
        'MK'=>'Macedonia',
        'MP'=>'Northern Mariana Islands',
        'NO'=>'Norway',
        'OM'=>'Oman',
        'PK'=>'Pakistan',
        'PW'=>'Palau',
        'PS'=>'Palestine',
        'PA'=>'Panama',
        'PG'=>'Papua New Guinea',
        'PY'=>'Paraguay',
        'PE'=>'Peru',
        'PH'=>'Philippines',
        'PN'=>'Pitcairn Island',
        'PL'=>'Poland',
        'PT'=>'Portugal',
        'PR'=>'Puerto Rico',
        'QA'=>'Qatar',
        'RE'=>'Réunion',
        'RO'=>'Romania',
        'RU'=>'Russia',
        'RW'=>'Rwanda',
        'BL'=>'Saint Barthélemy',
        'SH'=>'Saint Helena, Ascension and Tristan da Cunha',
        'KN'=>'Saint Kitts and Nevis',
        'LC'=>'Saint Lucia',
        'MF'=>'Saint Martin',
        'PM'=>'Saint Pierre and Miquelon',
        'VC'=>'Saint Vincent and the Grenadines',
        'WS'=>'Samoa',
        'SM'=>'San Marino',
        'ST'=>'São Tomé and Príncipe',
        'SA'=>'Saudi Arabia',
        'SN'=>'Senegal',
        'RS'=>'Serbia',
        'SC'=>'Seychelles',
        'SL'=>'Sierra Leone',
        'SG'=>'Singapore',
        'SX'=>'Sint Maarten',
        'SK'=>'Slovakia',
        'SI'=>'Slovenia',
        'SB'=>'Solomon Islands',
        'SO'=>'Somalia',
        'ZA'=>'South Africa',
        'GS'=>'South Georgia and the South Sandwich Islands',
        'SS'=>'South Sudan',
        'ES'=>'Spain',
        'LK'=>'Sri Lanka',
        'SD'=>'Sudan',
        'SR'=>'Suriname',
        'SJ'=>'Svalbard and Jan Mayen',
        'SE'=>'Sweden',
        'CH'=>'Switzerland',
        'SY'=>'Syria',
        'TW'=>'Taiwan',
        'TJ'=>'Tajikistan',
        'TZ'=>'Tanzania',
        'TH'=>'Thailand',
        'TL'=>'East Timor ',
        'TG'=>'Togo',
        'TK'=>'Tokelau',
        'TO'=>'Tonga',
        'TT'=>'Trinidad and Tobago',
        'TN'=>'Tunisia',
        'TR'=>'Turkey',
        'TM'=>'Turkmenistan',
        'TC'=>'Turks and Caicos Islands',
        'TV'=>'Tuvalu',
        'UG'=>'Uganda',
        'UA'=>'Ukraine',
        'AE'=>'United Arab Emirates',
        'UAE'=>'United Arab Emirates',
        'GB'=>'United Kingdom',
        'UK'=>'United Kingdom',
        'US'=>'United States',
        'USA'=>'United States',
        'UM'=>'United States Minor Outlying Islands',
        'UY'=>'Uruguay',
        'UZ'=>'Uzbekistan',
        'VU'=>'Vanuatu',
        'VE'=>'Venezuela',
        'VN'=>'Vietnam',
        'VG'=>'British Virgin Islands',
        'VI'=>'United States Virgin Islands',
        'WF'=>'Wallis and Futuna',
        'EH'=>'Western Sahara',
        'YE'=>'Yemen',
        'ZM'=>'Zambia',
        'ZW'=>'Zimbabwe'
    };
            
    public static final Map<String, String> stateNameToAbbrev = new Map<String, String>{
        'Alabama' => 'AL',
        'Alaska' => 'AK',
        'Arizona' => 'AZ',
        'Arkansas' => 'AR',
        'California' => 'CA',
        'Colorado' => 'CO',
        'Connecticut' => 'CT',
        'Delaware' => 'DE',
        'Florida' => 'FL',
        'Georgia' => 'GA',
        'Hawaii' => 'HI',
        'Idaho' => 'ID',
        'Illinois' => 'IL',
        'Indiana' => 'IN',
        'Iowa' => 'IA',
        'Kansas' => 'KS',
        'Kentucky' => 'KY',
        'Louisiana' => 'LA',
        'Maine' => 'ME',
        'Maryland' => 'MD',
        'Massachusetts' => 'MA',
        'Michigan' => 'MI',
        'Minnesota' => 'MN',
        'Mississippi' => 'MS',
        'Missouri' => 'MO',
        'Montana' => 'MT',
        'Nebraska' => 'NE',
        'Nevada' => 'NV',
        'New Hampshire' => 'NH',
        'New Jersey' => 'NJ',
        'New Mexico' => 'NM',
        'New York' => 'NY',
        'North Carolina' => 'NC',
        'North Dakota' => 'ND',
        'Ohio' => 'OH',
        'Oklahoma' => 'OK',
        'Oregon' => 'OR',
        'Pennsylvania' => 'PA',
        'Rhode Island' => 'RI',
        'South Carolina' => 'SC',
        'South Dakota' => 'SD',
        'Tennessee' => 'TN',
        'Texas' => 'TX',
        'Utah' => 'UT',
        'Vermont' => 'VT',
        'Virginia' => 'VA',
        'Washington' => 'WA',
        'West Virginia' => 'WV',
        'Wisconsin' => 'WI',
        'Wyoming' => 'WY',
        'Alberta' => 'AB',
        'British Columbia' => 'BC',
        'Manitoba' => 'MB',
        'New Brunswick' => 'NB',
        'Newfoundland and Labrador' => 'NL',
        'Nova Scotia' => 'NS',
        'Northwest Territories' => 'NT',
        'Nunavut' => 'NU',
        'Ontario' => 'ON',
        'Prince Edward Island' => 'PE',
        'Quebec' => 'QC',
        'Saskatchewan' => 'SK',
        'Yukon' => 'YT',
        'New South Wales' => 'NSW',
        'Queensland' => 'QLD',
        'South Australia' => 'SA',
        'Tasmania' => 'TAS',
        'Victoria' => 'VIC',
        'Western Australia' => 'WA',
        'Singapore' => '',
        'London' => '',
        'Hong Kong' => '',
        'Hong Kong Island' => '',
        'N/A' => '',
        'Xx'=> ''
    };

    public static void normalizeAddress(List<npsp__Address__c> addresses) {
        for (npsp__Address__c addr : addresses) {
            List<String> postScrubAddressComponents = new List<String>();
            if (!addr.npsp__Verified__c) {
                if (!String.isBlank(addr.npsp__MailingStreet__c)) {
                    if (addr.npsp__MailingStreet__c.toLowercase().equals(addr.npsp__MailingStreet__c) || addr.npsp__MailingStreet__c.toUppercase().equals(addr.npsp__MailingStreet__c)) {
                        addr.npsp__MailingStreet__c = DataQualityUtilities.capitalizeFirstLetter(addr.npsp__MailingStreet__c);
                    }
                    addr.npsp__MailingStreet__c = streetAbbreviations(addr.npsp__MailingStreet__c);
                    if (!String.isBlank(addr.npsp__MailingStreet__c)) {postScrubAddressComponents.add(addr.npsp__MailingStreet__c);}
                }
                if (!String.isBlank(addr.npsp__MailingStreet2__c)) {              
                    if (addr.npsp__MailingStreet2__c.toLowercase().equals(addr.npsp__MailingStreet2__c) || addr.npsp__MailingStreet2__c.toUppercase().equals(addr.npsp__MailingStreet2__c)) {
                        addr.npsp__MailingStreet2__c = DataQualityUtilities.capitalizeFirstLetter(addr.npsp__MailingStreet2__c);
                    }                            
                    addr.npsp__MailingStreet2__c = streetAbbreviations(addr.npsp__MailingStreet2__c);
                    if (!String.isBlank(addr.npsp__MailingStreet2__c)) {postScrubAddressComponents.add(addr.npsp__MailingStreet2__c);}
                }
                if (!String.isBlank(addr.npsp__MailingCity__c)) {               
                    if (addr.npsp__MailingCity__c.toLowercase().equals(addr.npsp__MailingCity__c) || addr.npsp__MailingCity__c.toUppercase().equals(addr.npsp__MailingCity__c)) {
                        addr.npsp__MailingCity__c = DataQualityUtilities.capitalizeFirstLetter(addr.npsp__MailingCity__c);
                    }
                    addr.npsp__MailingCity__c = streetAbbreviations(addr.npsp__MailingCity__c);
                    if (!String.isBlank(addr.npsp__MailingCity__c)) {postScrubAddressComponents.add(addr.npsp__MailingCity__c);}
                }                
                if (!String.isBlank(addr.npsp__MailingState__c)) {              
                    if (addr.npsp__MailingState__c.toLowercase().equals(addr.npsp__MailingState__c) || addr.npsp__MailingState__c.toUppercase().equals(addr.npsp__MailingState__c)) {
                        addr.npsp__MailingState__c = DataQualityUtilities.capitalizeFirstLetter(addr.npsp__MailingState__c);
                    }
                    if (addr.npsp__MailingState__c.length() <= 3) {
                        addr.npsp__MailingState__c = addr.npsp__MailingState__c.toUppercase();
                    }
                    if (stateNameToAbbrev.containsKey(addr.npsp__MailingState__c)) {
                        addr.npsp__MailingState__c = stateNameToAbbrev.get(addr.npsp__MailingState__c);
                    }
                    if (!String.isBlank(addr.npsp__MailingState__c)) {postScrubAddressComponents.add(addr.npsp__MailingState__c);}
                }
                if (!String.isBlank(addr.npsp__MailingPostalCode__c)) {      
                    addr.npsp__MailingPostalCode__c = streetAbbreviations(addr.npsp__MailingPostalCode__c);
                    addr.npsp__MailingPostalCode__c = addr.npsp__MailingPostalCode__c.toUppercase();
                    if (Pattern.matches('^[0-9]{7}$', addr.npsp__MailingPostalCode__c) && (addr.npsp__MailingCountry__c == 'JP' || addr.npsp__MailingCountry__c == 'Japan')) {addr.npsp__MailingPostalCode__c = addr.npsp__MailingPostalCode__c.substring(0,3) + '-' + addr.npsp__MailingPostalCode__c.substring(3,7);}
                    if (!String.isBlank(addr.npsp__MailingPostalCode__c)) {postScrubAddressComponents.add(addr.npsp__MailingPostalCode__c);}
                }
                if (!String.isBlank(addr.npsp__MailingCountry__c)) {                
                    String countryCode = addr.npsp__MailingCountry__c.toUpperCase();
                    if (ISOCodeToCountryName.containsKey(countryCode)) {
                        addr.npsp__MailingCountry__c = ISOCodeToCountryName.get(countryCode);
                    }
                	postScrubAddressComponents.add(addr.npsp__MailingCountry__c);				
                }
                addr.Original_Address_Scrubbed__c = String.join(postScrubAddressComponents, ', ');
                if (addr.Original_Address_Scrubbed__c.length() > 255) {addr.Original_Address_Scrubbed__c = addr.Original_Address_Scrubbed__c.substring(0,255);}
            }
        }  
    }
    
    public static String streetAbbreviations(String streetAddress) {
        streetAddress = streetAddress.replaceAll('\\b[A|a]{1}[V|v]{1}[E|e]{1}[N|n]{1}[U|u]{1}[E|e]{1}\\b', 'Ave');
        streetAddress = streetAddress.replaceAll('\\b[S|s]{1}[T|t]{1}[R|r]{1}[E|e]{2}[T|t]{1}\\b', 'St');
        streetAddress = streetAddress.replaceAll('\\b[R|r]{1}[O|o]{1}[A|a]{1}[D|d]{1}\\b', 'Rd');
        streetAddress = streetAddress.replaceAll('\\b[B|b]{1}[O|o]{1}[U|u]{1}[L|l]{1}[E|e]{1}[V|v]{1}[A|a]{1}[R|r]{1}[D|d]{1}\\b', 'Blvd');
        streetAddress = streetAddress.replaceAll('\\b[L|l]{1}[A|a]{1}[N|n]{1}[E|e]{1}\\b', 'Ln');
        streetAddress = streetAddress.replaceAll('\\b[D|d]{1}[R|r]{1}[I|i]{1}[V|v]{1}[E|e]{1}\\b', 'Dr');                        
        streetAddress = streetAddress.replaceAll('\\b[S|s]{1}[U|u]{1}[I|i]{1}[T|t]{1}[E|e]{1}\\b', 'Ste');
		streetAddress = streetAddress.replaceAll('\\b[P|p]{1}[L|l]{1}[A|a]{1}[C|c]{1}[E|e]{1}\\b', 'Pl');
		streetAddress = streetAddress.replaceAll('\\b[F|f]{1}[L|l]{1}[O|o]{2}[R|r]{1}\\b', 'Fl');
        streetAddress = streetAddress.replaceAll('\\b[A|a]{1}[P|p]{1}[A|a]{1}[R|r]{1}[T|t]{1}[M|m]{1}[E|e]{1}[N|n]{1}[T|t]{1}\\b', 'Apt');
        streetAddress = streetAddress.replaceAll('\\b[R|r]{1}[O|o]{2}[M|m]{1}\\b', 'Rm');
        streetAddress = streetAddress.replaceAll('\\b[B|b]{1}[U|u]{1}[I|i]{1}[L|l]{1}[D|d]{1}[I|i]{1}[N|n]{1}[G|g]{1}\\b', 'Bldg');
        streetAddress = streetAddress.replaceAll('\\b[B|b]{1}[L|l]{1}[O|o]{1}[C|c]{1}[K|k]{1}\\b', 'Blk');
        streetAddress = streetAddress.replaceAll('\\b[C|c]{1}[E|e]{1}[N|n]{1}[T|t]{1}[E|e]{1}[R|r]{1}\\b', 'Ctr');
        streetAddress = streetAddress.replaceAll('\\b[P|p]{1}[A|a]{1}[R|r]{1}[K|k]{1}[W|w]{1}[A|a]{1}[Y|y]{1}\\b', 'Pkwy');
        streetAddress = streetAddress.replaceAll('\\b[E|e]{1}[X|x]{1}[P|p]{1}[R|r]{1}[E|e]{1}[S|s]{2}[W|w]{1}[A|a]{1}[Y|y]{1}\\b', 'Expy');
        streetAddress = streetAddress.replaceAll('\\b[H|h]{1}[I|i]{1}[G|g]{1}[H|h]{1}[W|w]{1}[A|a]{1}[Y|y]{1}\\b', 'Hwy');
        streetAddress = streetAddress.replaceAll('\\b[C|c]{1}[O|o]{1}[U|u]{1}[R|r]{1}[T|t]{1}\\b', 'Ct');
        streetAddress = streetAddress.replaceAll('\\b[R|r]{1}[O|o]{1}[U|u]{1}[T|t]{1}[E|e]{1}\\b', 'Rte');
        streetAddress = streetAddress.replaceAll('\\b[M|m]{1}[O|o]{1}[U|u]{1}[N|n]{1}[T|t]{1}\\b', 'Mt');
        streetAddress = streetAddress.replaceAll('\\b[S|s]{1}[A|a]{1}[I|i]{1}[N|n]{1}[T|t]{1}\\b', 'St');
        streetAddress = streetAddress.replaceAll('\\b[P|p]{1}[L|l]{1}[A|a]{1}[Z|z]{1}[A|a]{1}\\b', 'Plz');
        streetAddress = streetAddress.replaceAll('\\b[J|j]{1}[U|u]{1}[N|n]{1}[C|c]{1}[T|t]{1}[I|i]{1}[O|o]{1}[N|n]{1}\\b', 'Jct');
        streetAddress = streetAddress.replaceAll('\\b[C|c]{1}[I|i]{1}[R|r]{1}[C|c]{1}[L|l]{1}[E|e]{1}\\b', 'Cir');       
        streetAddress = streetAddress.replaceAll('[.]', ''); 
        streetAddress = streetAddress.replaceAll('\\b[N|n]{1}[/]?[A|a]{1}(, )?\\b', '');
        streetAddress = streetAddress.replaceAll('\\b[X|x]{1,}\\b', '');
        streetAddress = streetAddress.replaceAll('\\b[Z|z]{1,}\\b', '');
        streetAddress = streetAddress.replaceAll('^[0]{1,}$', '');
        streetAddress = streetAddress.replaceAll('[,]\\s?$', '');
        return streetAddress;
    }
    
}
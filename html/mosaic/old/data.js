var schedule = {
    '241': ['paper', 'paper', 'paper', 'paper'],
    '242': ['paper', 'note', 'paper', 'note', 'paper'],
    '243': ['course'],
    '251': ['note', 'note', 'paper', 'note', 'note', 'paper'],
    '252': ['paper', 'note', 'note', 'paper', 'paper'],
    '253': ['course'],

    '342': ['paper', 'paper', 'note', 'note', 'note', 'note'],
    '343': ['course'],
    '361': ['course'],
    '363': ['sig'],
    '351': ['paper', 'paper', 'paper', 'paper'],
    '352': ['paper', 'paper', 'paper', 'note', 'note'],

    'Bordeaux': ['paper', 'paper', 'paper', 'paper'],
    'Bleu':     ['paper', 'note', 'note', 'paper', 'paper'],
    'Havane':   ['panel']
};

var filtersData = [
    {
        "filter": "Design",
        "items": [
            {
                "title": "Bricolage: Example-Based Retargetting for Web Design",
                "authors": "Ranjitha Kumar, Jerry O. Talton, Salman Ahmad, Scott R. Klemmer",
                "affiliation": "Stanford University",
                "video": "/videos/video0.mp4",
            },
            {
                "title": "Early and Repeated Exposure to Examples Improves Creative Work",
                "authors": "Chinmay Kulkarni, Steven P Dow, Scott R Klemmer	",
                "affiliation": "Stanford University",
                "video": "/videos/video6.mp4",
            },
            {
                "title": "A Platform for Large-Scale Machine Learning on Web Design",
                "authors": "Arvind Satyanarayan, Maxine Lim, Scott R Klemmer",
                "affiliation": "Stanford University",
                "video": "/videos/video2.mp4",
            },
            {
                "title": "d.tour: Style-based Exploration of Design Example Galleries",
                "authors": "Daniel Ritchie, Ankita Arvind Kejriwal, Scott R Klemmer",
                "affiliation": "Stanford University",
                "video": "/videos/video7.mp4",
            },
            // {
            //     "title": "Prototyping Dynamics: Sharing Multiple Designs Improves Exploration, Group Rapport, and Results",
            //     "authors": "Steven P Dow, Julie Fortuna, Dan Schwartz, Beth Altringer, Daniel L Schwartz, and Scott R Klemmer",
            //     "affiliation": "Stanford University",
            //     "video": "/videos/video0.mp4",
            // }
        ]
    },
    {
        "filter": "Health",
        "items": [
            {
                "title": "Identity construction environments: supporting a virtual therpeutic community of pediatric patients undergoing dialysis",
                "authors": "Marina U. Bers, Joseph Gonzalez-Heydrich, David Ray DeMaso",
                "affiliation": "MIT Media Lab; Children's Hospital",
                "video": "/videos/video1.mp4"
            },
            {
                "title": "Voice-enabled structured medical reporting",
                "authors": "Mary-Marshall Teel, Rachael Sokolowski, David Rosenthal, Matt Belge",
                "affiliation": "Lernout & Hauspie Speech Products",
                "video": "/videos/video7.mp4"
            },
            {
                "title": "MedSpeak: report creation with continuous speech recognition",
                "authors": "Jennifer Lai, John Vergo",
                "affiliation": "IBM Watson Research Center",
                "video": "/videos/video3.mp4"
            }
        ]
    },
    {
        "filter": "Environment",
        "items": [
            {
                "title": "Waterbot: exploring feedback and persuasive techniques",
                "authors": "Ernesto Arroyo, Leonardo Bonanni, Ted Selker",
                "affiliation": "MIT Media Lab",
                "video": "/videos/video2.mp4"
            },
            {
                "title": "Fast track article: Disaggregated water sensing from a single, pressure-based sensor: An extended analysis of HydroSense using staged experiments",
                "authors": "Eric Larson, Jon Froehlich, Tim Campbell, Conor Haggerty, Les Atlas, James Fogarty",
                "affiliation": "Electrical Engineering, University of Washington; Computer Science and Engineering, University of Washington",
                "video": "/videos/video8.mp4"
            },
            {
                "title": "The Design and Evaluation of Prototype Eco-Feedback Displays for Fixture-Level Water Usage Data.",
                "authors": "Jon Froehlich, Leah Findlater, Marilyn Ostergren, Solai Ramanathan, Josh Peterson, Inness Wragg, Eric Larson, Fabia Fu, Mazhengmin Bai, Shwetak N. Patel, James A. Landay",
                "affiliation": "University of Washington; University of Maryland",
                "video": "/videos/video4.mp4"
            },
            {
                "title": "TheLightWave: Using Compact Fluorescent Lights as Sensors",
                "authors": "Sidhant Gupta, Ke-Yu Chen, Matthew S. Reynolds, Shwetak N. Patel",
                "affiliation": "University of Washington; Duke University",
                "video": "/videos/video8.mp4"
            },
        ]
    },
    {
        "filter": "Crowdsourcing",
        "items": [
            {
                "title": "Crowdsourcing user studies with Mechanical Turk",
                "authors": "Aniket Kittur, Ed H. Chi and Bongwon Suh",
                "affiliation": "PARC",
                "video": "/videos/video3.mp4"
            },
            {
                "title": "Crowds in Two Seconds: Enabling Realtime Crowd-Powered Interfaces",
                "authors": "Michael Bernstein, Joel Brandt, Rob Miller, and David Karger",
                "affiliation": "MIT CSAIL; Adobe Systems",
                "video": "/videos/video9.mp4"
            },
            {
                "title": "Soylent: A Word Processor with a Crowd Inside",
                "authors": "Michael Bernstein, Greg Little, Rob Miller, Bjoern Hartmann, Mark Ackerman, David Karger, David Crowell, and Katrina Panovich",
                "affiliation": "MIT CSAIL; University of California, Berkeley; University of Michigan",
                "video": "/videos/video5.mp4"
            },
            {
                "title": "PingPong++: Community Customization in Games and Entertainment",
                "authors": "Xiao Xiao, Michael Bernstein, Lining Yao, David Lakatos, Lauren Gust, Kojo Acquah, and Hiroshi Ishii",
                "affiliation": "MIT Media Lab; MIT CSAIL",
                "video": "/videos/video9.mp4"
            },
            // {
            //     "title": "Personalization via Friendsourcing",
            //     "authors": "Michael Bernstein, Desney Tan, Greg Smith, Mary Czerwinski, and Eric Horvitz",
            //     "affiliation": "MIT CSAIL; Microsoft Research",
            //     "video": "/videos/video2.mp4"
            // },
            // {
            //     "title": "Strategies for Crowdsourcing Social Data Analysis",
            //     "authors": "Wesley Willett, Jeffrey Heer, Maneesh Agrawala",
            //     "affiliation": "University of California, Berkeley; Stanford University",
            //     "video": "/videos/video2.mp4"
            // }
        ]
    },
    {
        "filter": "Visualization",
        "items": [
            {
                "title": "Beyond visual acuity: the perceptual scalability of information visualizations for large displays",
                "authors": "Beth Yost, Yonca Haciahmetoglu, Chris North",
                "affiliation": "PARC",
                "video": "/videos/video4.mp4"
            },
            {
                "title": "Color Naming Models for Color Selection, Image Editing and Palette Design",
                "authors": "Jeffrey Heer and Maureen Stone",
                "affiliation": "Stanford University; Tableau Software",
                "video": "/videos/video10.mp4"
            },
            {
                "title": "Interpretation and Trust: Designing Model-Driven Visualizations for Text Analysis",
                "authors": "Jason Chuang, Daniel Ramage, Christopher D. Manning, Jeffrey Heer",
                "affiliation": "Stanford University",
                "video": "/videos/video6.mp4"
            },
            {
                "title": "Arc Length-based Aspect Ratio Selection",
                "authors": "Justin Talbot, John Gerth, Pat Hanrahan",
                "affiliation": "Stanford University",
                "video": "/videos/video10.mp4"
            },
            // {
            //     "title": "D3: Data-Driven Documents",
            //     "authors": "Michael Bostock, Vadim Ogievetsky, Jeffrey Heer",
            //     "affiliation": "Stanford University",
            //     "video": "/videos/video1.mp4"
            // },
            // {
            //     "title": "Divided Edge Bundling for Directional Network Data",
            //     "authors": "David Selassie, Brandon Heller, Jeffrey Heer",
            //     "affiliation": "Stanford University",
            //     "video": "/videos/video1.mp4"
            // }
        ]
    },
    {
        "filter": "Education",
        "items": [
            {
                "title": "The validity of a virtual human experience for interpersonal skills education",
                "authors": "Kyle Johnsen, Andrew Raij, Amy Stevens, D. Scott Lind, Benjamin",
                "affiliation": "Stanford University",
                "video": "/videos/video5.mp4"
            },
            {
                "title": "Teachers as simulation programmers: minimalist learning and reuse",
                "authors": "Mary Beth Rosson, Cheryl D. Seals",
                "affiliation": "Virginia Tech",
                "video": "/videos/video1.mp4"
            }
        ]
    }
];
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firestore
cred = credentials.Certificate("tool/service.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

professionals_list = [
  {
    "name": "Dr. Cyriac P J",
    "hospital": "Dr. Cyriac PJ Clinic",
    "location": "Market Road, Ernakulam",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Pratheesh",
    "hospital": "Solace Neurobehavioral Center",
    "location": "Ayyappankavu, Ernakulam",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Praveen Arathil",
    "hospital": "La Smilez",
    "location": "Pachalam, Ernakulam",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Shobitha George",
    "hospital": "Jyothi Clinic",
    "location": "Ernakulam South, Ernakulam",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Tehmina Asif",
    "hospital": "Softmind",
    "location": "Panampilly Nagar, Ernakulam",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Namitha M Das",
    "hospital": "Aster Medcity",
    "location": "Cheranalloor, Ernakulam",
    "phone": "0484 - 6699999",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Kumar K A",
    "hospital": "KIMSHEALTH",
    "location": "Anayara P.O, Trivandrum",
    "phone": "Contact via KIMSHEALTH",
    "speciality": "Senior Consultant - Psychiatry & Behavioral Medicine"
  },
  {
    "name": "Dr. M. Chandrasekharan Nair",
    "hospital": "Nair's Hospital",
    "location": "Cochin, Kerala",
    "phone": "Contact via Nair's Hospital",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Dr. Elsie Oommen",
    "hospital": "Medical Trust Hospital",
    "location": "Cochin, Kerala",
    "phone": "0484 - 2358001",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Meethu Maria Paul",
    "hospital": "PVS Memorial Hospital",
    "location": "Cochin, Kerala",
    "phone": "0484 - 41828888",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Dr. Bindu Menon",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ponekkara, Kochi, Kerala - 682 041",
    "phone": "+91 484 2852100",
    "speciality": "Professor and Head - Psychiatry"
  },
  {
    "name": "Dr. Kathleen Anne Mathew",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ponekkara, Kochi, Kerala - 682 041",
    "phone": "+91 484 2852100",
    "speciality": "Associate Professor - Psychiatry"
  },
  {
    "name": "Dr. Lakshmi K P",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ponekkara, Kochi, Kerala - 682 041",
    "phone": "+91 484 2852100",
    "speciality": "Associate Professor - Psychiatry"
  },
  {
    "name": "Dr. Dhanya Chandran",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ponekkara, Kochi, Kerala - 682 041",
    "phone": "+91 484 2852100",
    "speciality": "Associate Professor and Head - Psychology"
  },
  {
    "name": "Bindu R",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ponekkara, Kochi, Kerala - 682 041",
    "phone": "+91 484 2852100",
    "speciality": "Assistant Professor - Clinical Psychology"
  },
  {
    "name": "Dr. Fathima B. P",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ponekkara, Kochi, Kerala - 682 041",
    "phone": "+91 484 2852100",
    "speciality": "Assistant Professor - Clinical Psychology"
  },
  {
    "name": "Gokul T. Priyan",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ponekkara, Kochi, Kerala - 682 041",
    "phone": "+91 484 2852100",
    "speciality": "Assistant Professor / Clinical Psychologist"
  },
  {
    "name": "Dr. Geo George",
    "hospital": "Mindful Rejuvenation Alphonsa Hospital",
    "location": "Karukutty, Angamaly, Ernakulam – 683572",
    "phone": "9995442200, 9645094738",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Nikhil George K",
    "hospital": "Thanal for Neuropsychiatry & De-addiction",
    "location": "Kothamangalam, Ernakulam – 686691",
    "phone": "psychiatry.pv@gmail.com",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Benzir Hussain",
    "hospital": "Carmel Hospital",
    "location": "Aluva, Ernakulam – 683 101",
    "phone": "info@carmelhospital.org",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Seethulakshmi D",
    "hospital": "AVM Hospital Cherukattu Pvt. Ltd.",
    "location": "Thodupuzha, Idukki – 685 586",
    "phone": "9779777242, 04862-242242",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Rima Joseph",
    "hospital": "Private Practice",
    "location": "Nettissery P.O., Thrissur – 680651",
    "phone": "9486641872",
    "speciality": "Clinical Psychologist"
  },
  {
    "name": "Dr. Manoj",
    "hospital": "MHAT (Mental Health Action Trust)",
    "location": "Kerala",
    "phone": "https://mhatkerala.org/",
    "speciality": "Psychiatrist & Founder"
  },
  {
    "name": "Dr. Tom C Babu",
    "hospital": "Caritas Hospital",
    "location": "Kottayam, Kerala",
    "phone": "Not specified",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Sanju George",
    "hospital": "Rajagiri Hospital",
    "location": "Aluva, Kochi, Kerala",
    "phone": "Contact via website",
    "speciality": "Psychiatrist"
  },
  {
    "name": "DR PRATHEESH PJ",
    "hospital": "Solace Neurobehavioral Center",
    "location": "Kakkanad / Palarivattom, Kochi",
    "phone": "+91 9746511100",
    "speciality": "CEO & Founder / Psychiatrist"
  },
  {
    "name": "DR RAMACHANDRAN KUTTY",
    "hospital": "Solace Neurobehavioral Center",
    "location": "Kakkanad / Palarivattom, Kochi",
    "phone": "+91 9746511100",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Mindmaris Team",
    "hospital": "Mindmaris - Biophilic Clinic",
    "location": "Kakkanad, Kochi, Kerala",
    "phone": "+91 8089090567",
    "speciality": "Psychologists & Psychiatrists"
  },
  {
    "name": "Vijaya Dhulipudi",
    "hospital": "Praan Mental Wellness",
    "location": "Online / In-person",
    "phone": "8142800800",
    "speciality": "Therapist / Counsellor"
  },
  {
    "name": "Mindleo Counselling Centre",
    "hospital": "Mindleo Counselling Centre",
    "location": "Kakkanad, Kochi, Kerala 683565",
    "phone": "087148 46663",
    "speciality": "Psychologists"
  },
  {
    "name": "Saranya B Raj",
    "hospital": "Hapinus Care",
    "location": "Kanjikuzhy P.O., Kottayam, PIN: 686 004",
    "phone": "92 0707 5151",
    "speciality": "Counseling Psychologist"
  },
  {
    "name": "Dr. Namitha Das",
    "hospital": "De Elite Mindcare",
    "location": "Palarivattom, Ernakulam, Kerala",
    "phone": "+91 7736 123 337",
    "speciality": "MD Psychiatry"
  },
  {
    "name": "Dr. Vineeth Mohan",
    "hospital": "Rajagiri Hospital",
    "location": "Aluva, Kerala 683112",
    "phone": "+91 484 290 5000",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Dr. Ashika. B. George",
    "hospital": "Specialists' Hospital",
    "location": "Ernakulam North, Kochi, Kerala - 682 018",
    "phone": "0484-2887800",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Abdul Bary A",
    "hospital": "NIMS Medicity",
    "location": "Neyyattinkara, Thiruvananthapuram, Kerala 695123",
    "phone": "0471 – 2223542",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Sreejith M Cheruvilakam",
    "hospital": "SP Medifort Hospital",
    "location": "Statue Junction, Thiruvananthapuram",
    "phone": "09054770945",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Anees Ali",
    "hospital": "Manassanthi Hospital",
    "location": "Malappuram",
    "phone": "+91 9544001717",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. U. Vivek",
    "hospital": "Renai Medicity Hospital / PNVM Hospital",
    "location": "Cochin",
    "phone": "9496229470",
    "speciality": "Child, Adolescent & Adult Psychiatry"
  },
  {
    "name": "Dr. R. Venugopal",
    "hospital": "City Hospital",
    "location": "Cochin (Ernakulam)",
    "phone": "0484 - 3043010",
    "speciality": "Senior Consultant Psychiatrist"
  },
  {
    "name": "Dr. Anjali Viswanath",
    "hospital": "Starcare Hospital",
    "location": "Kozhikode",
    "phone": "+91 495 248 99 99",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Saleem P.P.",
    "hospital": "Centre for Neuro & Psychiatry",
    "location": "Malappuram",
    "phone": "04933 - 228807",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. K.S. Agustine",
    "hospital": "Kudiyirippil House",
    "location": "Cochin (Ernakulam)",
    "phone": "9447747618",
    "speciality": "Consultant Psychiatrist (Child Guidance)"
  },
  {
    "name": "Dr. Balakrishnan K.R.",
    "hospital": "Co-Operative Hospital",
    "location": "Calicut (Kozhikode)",
    "phone": "0495 - 2766820",
    "speciality": "Child Guidance Clinic"
  },
  {
    "name": "Dr. (Col) P. Ramachandran Kutty",
    "hospital": "Lourde Hospital",
    "location": "Cochin (Ernakulam)",
    "phone": "98472 - 04300",
    "speciality": "Senior Consultant Psychiatrist"
  },
  {
    "name": "Dr. Somanath C.P.",
    "hospital": "Lakeshore Hospital",
    "location": "Cochin (Ernakulam)",
    "phone": "0484 - 2701032",
    "speciality": "Psychiatry & Child Guidance"
  }
]

def batch_upload():
    batch = db.batch()
    for entry in professionals_list:
        doc_ref = db.collection('professionals').document()
        batch.set(doc_ref, entry)
    
    batch.commit()
    print("All professionals successfully uploaded.")

batch_upload()
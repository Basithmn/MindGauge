import firebase_admin
from firebase_admin import credentials, firestore
import re

# Initialize Firestore
cred = credentials.Certificate("tool/service.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

professionals_list = [
  {
    "name": "Dr. Cyriac P J",
    "hospital": "Dr. Cyriac PJ Clinic",
    "location": "Ernakulam",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Pratheesh",
    "hospital": "Solace Neurobehavioral Center",
    "location": "Ernakulam",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Praveen Arathil",
    "hospital": "La Smilez",
    "location": "Ernakulam",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Shobitha George",
    "hospital": "Jyothi Clinic",
    "location": "Ernakulam",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Tehmina Asif",
    "hospital": "Softmind",
    "location": "Ernakulam",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Namitha M Das",
    "hospital": "Aster Medcity",
    "location": "Ernakulam",
    "phone": "0484 - 6699999",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Kumar K A",
    "hospital": "KIMSHEALTH",
    "location": "Thiruvananthapuram",
    "phone": "Contact via KIMSHEALTH",
    "speciality": "Senior Consultant - Psychiatry & Behavioral Medicine"
  },
  {
    "name": "Dr. M. Chandrasekharan Nair",
    "hospital": "Nair's Hospital",
    "location": "Ernakulam",
    "phone": "Contact via Nair's Hospital",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Dr. Elsie Oommen",
    "hospital": "Medical Trust Hospital",
    "location": "Ernakulam",
    "phone": "0484 - 2358001",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Meethu Maria Paul",
    "hospital": "PVS Memorial Hospital",
    "location": "Ernakulam",
    "phone": "0484 - 41828888",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Dr. Bindu Menon",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ernakulam",
    "phone": "+91 484 2852100",
    "speciality": "Professor and Head - Psychiatry"
  },
  {
    "name": "Dr. Kathleen Anne Mathew",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ernakulam",
    "phone": "+91 484 2852100",
    "speciality": "Associate Professor - Psychiatry"
  },
  {
    "name": "Dr. Lakshmi K P",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ernakulam",
    "phone": "+91 484 2852100",
    "speciality": "Associate Professor - Psychiatry"
  },
  {
    "name": "Dr. Dhanya Chandran",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ernakulam",
    "phone": "+91 484 2852100",
    "speciality": "Associate Professor and Head - Psychology"
  },
  {
    "name": "Bindu R",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ernakulam",
    "phone": "+91 484 2852100",
    "speciality": "Assistant Professor - Clinical Psychology"
  },
  {
    "name": "Dr. Fathima B. P",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ernakulam",
    "phone": "+91 484 2852100",
    "speciality": "Assistant Professor - Clinical Psychology"
  },
  {
    "name": "Gokul T. Priyan",
    "hospital": "Amrita Hospital, Kochi",
    "location": "Ernakulam",
    "phone": "+91 484 2852100",
    "speciality": "Assistant Professor / Clinical Psychologist"
  },
  {
    "name": "Dr. Geo George",
    "hospital": "Mindful Rejuvenation Alphonsa Hospital",
    "location": "Ernakulam",
    "phone": "9995442200, 9645094738",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Nikhil George K",
    "hospital": "Thanal for Neuropsychiatry & De-addiction",
    "location": "Ernakulam",
    "phone": "psychiatry.pv@gmail.com",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Benzir Hussain",
    "hospital": "Carmel Hospital",
    "location": "Ernakulam",
    "phone": "info@carmelhospital.org",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Seethulakshmi D",
    "hospital": "AVM Hospital Cherukattu Pvt. Ltd.",
    "location": "Idukki",
    "phone": "9779777242, 04862-242242",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Rima Joseph",
    "hospital": "Private Practice",
    "location": "Thrissur",
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
    "location": "Kottayam",
    "phone": "Not specified",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Sanju George",
    "hospital": "Rajagiri Hospital",
    "location": "Ernakulam",
    "phone": "Contact via website",
    "speciality": "Psychiatrist"
  },
  {
    "name": "DR PRATHEESH PJ",
    "hospital": "Solace Neurobehavioral Center",
    "location": "Ernakulam",
    "phone": "+91 9746511100",
    "speciality": "CEO & Founder / Psychiatrist"
  },
  {
    "name": "DR RAMACHANDRAN KUTTY",
    "hospital": "Solace Neurobehavioral Center",
    "location": "Ernakulam",
    "phone": "+91 9746511100",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Mindmaris Team",
    "hospital": "Mindmaris - Biophilic Clinic",
    "location": "Ernakulam",
    "phone": "+91 8089090567",
    "speciality": "Psychologists & Psychiatrists"
  },
  {
    "name": "Vijaya Dhulipudi",
    "hospital": "Praan Mental Wellness",
    "location": "Online",
    "phone": "8142800800",
    "speciality": "Therapist / Counsellor"
  },
  {
    "name": "Mindleo Counselling Centre",
    "hospital": "Mindleo Counselling Centre",
    "location": "Ernakulam",
    "phone": "087148 46663",
    "speciality": "Psychologists"
  },
  {
    "name": "Saranya B Raj",
    "hospital": "Hapinus Care",
    "location": "Kottayam",
    "phone": "92 0707 5151",
    "speciality": "Counseling Psychologist"
  },
  {
    "name": "Dr. Namitha Das",
    "hospital": "De Elite Mindcare",
    "location": "Ernakulam",
    "phone": "+91 7736 123 337",
    "speciality": "MD Psychiatry"
  },
  {
    "name": "Dr. Vineeth Mohan",
    "hospital": "Rajagiri Hospital",
    "location": "Ernakulam",
    "phone": "+91 484 290 5000",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Dr. Ashika. B. George",
    "hospital": "Specialists' Hospital",
    "location": "Ernakulam",
    "phone": "0484-2887800",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Abdul Bary A",
    "hospital": "NIMS Medicity",
    "location": "Thiruvananthapuram",
    "phone": "0471 – 2223542",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Sreejith M Cheruvilakam",
    "hospital": "SP Medifort Hospital",
    "location": "Thiruvananthapuram",
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
    "location": "Ernakulam",
    "phone": "9496229470",
    "speciality": "Child, Adolescent & Adult Psychiatry"
  },
  {
    "name": "Dr. R. Venugopal",
    "hospital": "City Hospital",
    "location": "Ernakulam",
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
    "location": "Ernakulam",
    "phone": "9447747618",
    "speciality": "Consultant Psychiatrist (Child Guidance)"
  },
  {
    "name": "Dr. Balakrishnan K.R.",
    "hospital": "Co-Operative Hospital",
    "location": "Kozhikode",
    "phone": "0495 - 2766820",
    "speciality": "Child Guidance Clinic"
  },
  {
    "name": "Dr. (Col) P. Ramachandran Kutty",
    "hospital": "Lourde Hospital",
    "location": "Ernakulam",
    "phone": "98472 - 04300",
    "speciality": "Senior Consultant Psychiatrist"
  },
  {
    "name": "Dr. Somanath C.P.",
    "hospital": "Lakeshore Hospital",
    "location": "Ernakulam",
    "phone": "0484 - 2701032",
    "speciality": "Psychiatry & Child Guidance"
  },
  {
    "name": "Dr. Elsie Oommen",
    "hospital": "Medical Trust Hospital",
    "location": "Ernakulam",
    "phone": "0484-2358001",
    "speciality": "Consultant Psychiatrist (20+ years experience)"
  },
  {
    "name": "Dr. Cyriac P J",
    "hospital": "Dr. Cyriac PJ Clinic",
    "location": "Ernakulam",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist (15+ years experience)"
  },
  {
    "name": "Dr. Namitha M Das",
    "hospital": "Aster Medcity",
    "location": "Ernakulam",
    "phone": "0484-6699999",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. K S Radhakrishnan",
    "hospital": "Dr. K S Radhakrishnan Clinic",
    "location": "Ernakulam",
    "phone": "0484 233 1111",
    "speciality": "Psychiatrist (44 years experience)"
  },
  {
    "name": "Dr. U. Vivek",
    "hospital": "Renai Medicity Hospital / PNVM Hospital",
    "location": "Ernakulam",
    "phone": "9496229470",
    "speciality": "Child, Adolescent & Adult Psychiatry, De-addiction"
  },
  {
    "name": "Dr. Meethu Maria Paul",
    "hospital": "PVS Memorial Hospital",
    "location": "Ernakulam",
    "phone": "0484-41828888",
    "speciality": "Consultant Psychiatrist (MRCPsych - UK trained)"
  },
  {
    "name": "Dr. Bindu Menon",
    "hospital": "Amrita Hospital",
    "location": "Ernakulam",
    "phone": "0484-4091111",
    "speciality": "Professor and Head - Psychiatry"
  },
  {
    "name": "Dr. S D Singh",
    "hospital": "K I M S Hospital",
    "location": "Ernakulam",
    "phone": "0484-2972411",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Abdul Bari A",
    "hospital": "NIMS Medicity / SK Hospital",
    "location": "Thiruvananthapuram",
    "phone": "0471-2223542",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Arun B Nair",
    "hospital": "Govt. Medical College / Private Consulting",
    "location": "Thiruvananthapuram",
    "phone": "Contact via MedicalKerala",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Jassar A J",
    "hospital": "Samagra Wellness",
    "location": "Thiruvananthapuram",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist (19 years experience)"
  },
  {
    "name": "Dr. Vini Vivek",
    "hospital": "The Mind",
    "location": "Thiruvananthapuram",
    "phone": "Contact via Practo",
    "speciality": "Psychiatrist (16 years experience)"
  },
  {
    "name": "Dr. R. Jayakumar",
    "hospital": "COSMO Politian Hospital",
    "location": "Thiruvananthapuram",
    "phone": "Contact via myUpchar",
    "speciality": "Senior Consultant Psychiatrist"
  },
  {
    "name": "Dr. Sreejith M Cheruvilakam",
    "hospital": "SP Medifort Hospital",
    "location": "Thiruvananthapuram",
    "phone": "09054770945",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Mohan Roy G",
    "hospital": "Govt. Medical College",
    "location": "Thiruvananthapuram",
    "phone": "0471-2528300",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Jitha G",
    "hospital": "KIMSHEALTH Trivandrum",
    "location": "Thiruvananthapuram",
    "phone": "+91 471 294 1400",
    "speciality": "General and Child & Adolescent Psychiatry"
  },
  {
    "name": "Dr. P. N. Suresh Kumar",
    "hospital": "National Hospital / IQRAA Hospital",
    "location": "Kozhikode",
    "phone": "0495-2723272",
    "speciality": "Psychiatrist (MBBS, MD, DNB, PhD)"
  },
  {
    "name": "Dr. Anjali Viswanath",
    "hospital": "Starcare Hospital",
    "location": "Kozhikode",
    "phone": "+91 495 248 99 99",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Balakrishnan K.R.",
    "hospital": "Co-Operative Hospital",
    "location": "Kozhikode",
    "phone": "0495-2766820",
    "speciality": "Child Guidance Clinic (CGC) Specialist"
  },
  {
    "name": "Dr. Saleem P.P.",
    "hospital": "Centre for Neuro & Psychiatry",
    "location": "Malappuram",
    "phone": "04933-228807",
    "speciality": "Psychiatrist (NIMHANS trained)"
  },
  {
    "name": "Dr. Anees Ali",
    "hospital": "Manassanthi Hospital",
    "location": "Malappuram",
    "phone": "+91 9544001717",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Marwa Kunheen",
    "hospital": "Manu Memorial Hospital",
    "location": "Malappuram",
    "phone": "Contact via MedicalKerala",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Dinesh Kumar M K",
    "hospital": "Edappal Hospital",
    "location": "Malappuram",
    "phone": "0494-2660100",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Nitin",
    "hospital": "Private Practice",
    "location": "Thrissur",
    "phone": "Contact via Clinic",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Biju Sunny",
    "hospital": "MIMS Hospital",
    "location": "Thrissur",
    "phone": "Contact via MedicalKerala",
    "speciality": "Child Psychiatrist"
  },
  {
    "name": "Dr. Jery Antony",
    "hospital": "Amala Medical College",
    "location": "Thrissur",
    "phone": "0487-2304000",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Arun Gopalakrishnan",
    "hospital": "AKG Memorial Cooperative Hospital",
    "location": "Kannur",
    "phone": "0497 276 2500",
    "speciality": "Psychiatrist (MBBS, DPM)"
  },
  {
    "name": "Dr. Nellicode Sreedharan",
    "hospital": "Sreedharan Clinic",
    "location": "Kannur",
    "phone": "Contact via Justdial",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Thajuddin K P",
    "hospital": "Dr Thaj Homoeopathy and Psychology Centre",
    "location": "Kannur",
    "phone": "Contact via Justdial",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Udayalekshmy B S",
    "hospital": "Mind Space Clinic",
    "location": "Kannur",
    "phone": "08071910149 Ext. 480",
    "speciality": "Psychiatrist (6 years experience)"
  },
  {
    "name": "Dr. Subin M S",
    "hospital": "Nikhil Hospital",
    "location": "Kannur",
    "phone": "Contact via Clinic",
    "speciality": "Psychiatrist (1 year experience)"
  },
  {
    "name": "Dr. Geomy G Chakkalakkudy",
    "hospital": "Jubilee Mission Medical College",
    "location": "Thrissur",
    "phone": "Contact via MedicalKerala",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Vipin Chandra",
    "hospital": "Leela Hospital and De Addiction Centre",
    "location": "Kottayam",
    "phone": "Contact via Clinic",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Lekshmy Gupthan",
    "hospital": "Govt. Medical College Kottayam",
    "location": "Kottayam",
    "phone": "0481-2592206",
    "speciality": "Professor and HOD - Psychiatry"
  },
  {
    "name": "Dr. Soumya Prakash",
    "hospital": "Govt. Medical College Kottayam",
    "location": "Kottayam",
    "phone": "0481-2592206",
    "speciality": "Assistant Professor - Psychiatry"
  },
  {
    "name": "Dr. D. George",
    "hospital": "Cardinal Speciality Hospital",
    "location": "Kottayam",
    "phone": "04822 243099",
    "speciality": "Mental Health Specialist & De-addiction"
  },
  {
    "name": "Dr. Kiran K",
    "hospital": "Modern Medicine",
    "location": "Kollam",
    "phone": "Contact via MedicalKerala",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Aravind S",
    "hospital": "MGM Muthoot Hospitals",
    "location": "Pathanamthitta",
    "phone": "Contact via Muthoot Healthcare",
    "speciality": "Psychiatrist (MBBS, DPM, DNB)"
  },
  {
    "name": "Dr. Sreerag Ashok",
    "hospital": "Unity Clinic",
    "location": "Pathanamthitta",
    "phone": "Contact via Unity Clinic",
    "speciality": "Psychiatrist (Family Counseling)"
  },
  {
    "name": "Dr. Christy Abraham",
    "hospital": "Pushpagiri Medical College Hospital",
    "location": "Pathanamthitta",
    "phone": "Contact via Pushpagiri",
    "speciality": "Psychiatrist (15+ years experience)"
  },
  {
    "name": "Dr. Riswin R Babu",
    "hospital": "KCM Hospital",
    "location": "Alappuzha",
    "phone": "0479-2382348",
    "speciality": "Psychiatrist (MBBS, MD)"
  },
  {
    "name": "Dr. Ruben John",
    "hospital": "Dr. KM Cherian Institute of Medical Sciences",
    "location": "Alappuzha",
    "phone": "Contact via MedicalKerala",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Shameena Abdullah",
    "hospital": "Private Practice",
    "location": "Alappuzha",
    "phone": "Contact via Kayamkulam Clinic",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Aleesha Sulaiman",
    "hospital": "Mary Matha Hospital",
    "location": "Idukki",
    "phone": "04862-200301",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Sameer Moideen",
    "hospital": "Sacred Heart Hospital",
    "location": "Idukki",
    "phone": "04862-200301",
    "speciality": "Psychiatrist (MBBS, MD)"
  },
  {
    "name": "Dr. Meera Ramanath",
    "hospital": "PK Das Hospital",
    "location": "Palakkad",
    "phone": "0466-2344500",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. C. D. Premadasan",
    "hospital": "Manomithra Institute of Medical Sciences",
    "location": "Palakkad",
    "phone": "0491-2531342",
    "speciality": "Alcohol & Drug De-addiction Specialist"
  },
  {
    "name": "Dr. Sreelakshmi Sethumadhavan Nair",
    "hospital": "Dr. Moopen's Medical College",
    "location": "Wayanad",
    "phone": "04936-287000",
    "speciality": "Psychiatry Services"
  },
  {
    "name": "Dr. Nellikode Sreedharan",
    "hospital": "PVS Sunrise Hospital",
    "location": "Wayanad",
    "phone": "Contact via PVS Sunrise",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. P M A Nishad",
    "hospital": "Aster MIMS Kasaragod",
    "location": "Kasaragod",
    "phone": "Contact via Aster Hospitals",
    "speciality": "Associate Consultant - Psychiatry (University Topper)"
  },
  {
    "name": "Dr. Avinash Desousa",
    "hospital": "Desousa Foundation",
    "location": "Mumbai",
    "phone": "022 2646 5150",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Ajit Dandekar",
    "hospital": "Nanavati Super Speciality Hospital",
    "location": "Mumbai",
    "phone": "022 2626 7500",
    "speciality": "Psychiatry (43 Years experience)"
  },
  {
    "name": "Dr. Sameer Malhotra",
    "hospital": "Max Super Speciality Hospital",
    "location": "New Delhi",
    "phone": "011 2651 5050",
    "speciality": "Director - Mental Health & Behavioral Sciences (23 Years exp)"
  },
  {
    "name": "Dr. Samir Parikh",
    "hospital": "Fortis Hospital",
    "location": "New Delhi",
    "phone": "011 4530 2222",
    "speciality": "Psychiatry (18 Years experience)"
  },
  {
    "name": "Dr. Naveen Kumar",
    "hospital": "Manipal Hospital",
    "location": "Bengaluru",
    "phone": "1800 102 5555",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Dr. Murali Raj",
    "hospital": "Manipal Hospital",
    "location": "Bengaluru",
    "phone": "1800 102 5555",
    "speciality": "Psychiatry (35 Years experience)"
  },
  {
    "name": "Dr. Johnson Pradeep",
    "hospital": "St. John's Medical College Hospital",
    "location": "Bengaluru",
    "phone": "080 2206 5000",
    "speciality": "Psychiatry"
  },
  {
    "name": "Dr. Arohi Vardhan",
    "hospital": "Cadabams Hospital",
    "location": "Bengaluru",
    "phone": "080 2668 5353",
    "speciality": "Psychiatry"
  },
  {
    "name": "Dr. Sivabalan Elangovan",
    "hospital": "Apollo Hospitals",
    "location": "Chennai",
    "phone": "044 2829 3333",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Dr. Vasantha Jayaraman",
    "hospital": "The Sole Clinic",
    "location": "Chennai",
    "phone": "Contact via Medindia",
    "speciality": "Psychiatry (26 Years experience)"
  },
  {
    "name": "Dr. Charan Teja Koganti",
    "hospital": "KIMS Hospitals",
    "location": "Hyderabad",
    "phone": "040 4488 5000",
    "speciality": "Neuropsychiatrist"
  },
  {
    "name": "Dr. Sanjay Garg",
    "hospital": "Fortis Hospital",
    "location": "Kolkata",
    "phone": "033 6628 4444",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Dr. Swapnil Deshmukh",
    "hospital": "Ruby Hall Clinic",
    "location": "Pune",
    "phone": "020 6645 5100",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Mrugesh Vaishnav",
    "hospital": "Samvedna Hospital",
    "location": "Ahmedabad",
    "phone": "079 2642 0285",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Shrikant Sharma",
    "hospital": "Manipal Hospital",
    "location": "Jaipur",
    "phone": "0141 223 2211",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Dr. Shailendra Kumar Singh",
    "hospital": "Medanta Hospital",
    "location": "Lucknow",
    "phone": "0522 4505050",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Sangeeta Dutta",
    "hospital": "Mind and Brain Clinic",
    "location": "Guwahati",
    "phone": "0361 245 6142",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Simmi Waraich",
    "hospital": "Fortis Hospital",
    "location": "Mohali",
    "phone": "0172 450 6122",
    "speciality": "Consultant Psychiatrist"
  },
  {
    "name": "Dr. Vivek Pratap Singh",
    "hospital": "Paras HMRI Hospital",
    "location": "Patna",
    "phone": "0612 710 7777",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. R.N. Sahu",
    "hospital": "Bansal Hospital",
    "location": "Bhopal",
    "phone": "0755 408 6000",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. J.P.S. Bakshi",
    "hospital": "Max Super Speciality Hospital",
    "location": "Dehradun",
    "phone": "0135 719 3000",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Ravi Sharma",
    "hospital": "Indira Gandhi Medical College",
    "location": "Shimla",
    "phone": "0177 280 4251",
    "speciality": "Head of Psychiatry"
  },
  {
    "name": "Dr. Arshad Hussain",
    "hospital": "Government Medical College",
    "location": "Srinagar",
    "phone": "0194 245 2017",
    "speciality": "Professor & Psychiatrist"
  },
  {
    "name": "Dr. Zelio De Figueiredo",
    "hospital": "Manipal Hospital",
    "location": "Panaji",
    "phone": "0832 304 8800",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Surjeet Sahoo",
    "hospital": "SUM Ultimate Medicare",
    "location": "Bhubaneswar",
    "phone": "0674 238 6290",
    "speciality": "Senior Consultant Psychiatrist"
  },
  {
    "name": "Dr. Siddhartha Sinha",
    "hospital": "CIP (Central Institute of Psychiatry)",
    "location": "Ranchi",
    "phone": "0651 245 1115",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Raman Sharma",
    "hospital": "Choithram Hospital",
    "location": "Indore",
    "phone": "0731 247 0000",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. C. Radhakanth",
    "hospital": "Care Hospitals",
    "location": "Visakhapatnam",
    "phone": "0891 332 7777",
    "speciality": "Psychiatrist"
  },
  {
    "name": "Dr. Mrinmay Kumar Das",
    "hospital": "Jaypee Hospital",
    "location": "Noida",
    "phone": "0120 412 2222",
    "speciality": "Psychiatry (24 Years experience)"
  },
  {
    "name": "Dr. Vipul Rastogi",
    "hospital": "Medanta The Medicity",
    "location": "Gurgaon",
    "phone": "0124 414 1414",
    "speciality": "Psychiatry (12 Years experience)"
  },
  {
    "name": "Dr. Sudheendra Huddar",
    "hospital": "Sukhibhava Health Care",
    "location": "Hubballi",
    "phone": "Contact via KSMHA",
    "speciality": "Consultant Neuro Psychiatrist"
  },
  {
    "name": "Dr. Shashikala I M",
    "hospital": "J.J. M Medical College",
    "location": "Davangere",
    "phone": "Contact via KSMHA",
    "speciality": "Psychiatry"
  },
  {
    "name": "Dr. Nitin Pattanshetti",
    "hospital": "KLE Centenary Charitable Hospital",
    "location": "Belagavi",
    "phone": "0831 247 3777",
    "speciality": "Psychiatry"
  },
  {
    "name": "Dr. Abhiram PN",
    "hospital": "Kasturba Medical College",
    "location": "Udupi",
    "phone": "0820 292 2761",
    "speciality": "Psychiatry"
  }

]

def generate_id(name):
    """Creates a clean, URL-friendly ID from the name."""
    return re.sub(r'[^a-z0-9]', '_', name.lower().strip())

def batch_upload():
    batch = db.batch()
    for entry in professionals_list:
        # Use a unique identifier (like Name or Phone) as the document ID
        # This ensures that running the script twice won't create duplicates
        doc_id = generate_id(entry['name']) 
        doc_ref = db.collection('professionals').document(doc_id)
        
        batch.set(doc_ref, entry)
    
    batch.commit()
    print(f"Successfully processed {len(professionals_list)} professionals.")

batch_upload()
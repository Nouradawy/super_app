# WhatsUnity

WhatsUnity is a comprehensive mobile platform designed to bridge the gap between property management and resident connection. Unlike standard group chats, WhatsUnity creates a structured, verified environment where every interaction is mapped to a specific building and apartment unit.

Built with Flutter and powered by a self-hosted Supabase backend, this application solves the chaos of unverified tenants and lost information. It introduces a dedicated "Brainstorming" governance module that separates critical decision-making polls from daily chatter, ensuring community voices are heard clearly.

🚀 Key Highlights
📍 Structured Identity: Residents are verified by Building & Apartment ID, ensuring you always know who your neighbors are.

🧠 Brainstorming Module: A dedicated space for voting and polling, preventing critical community decisions from getting buried in chat streams.

🛠️ Unified Services: One-tap reporting for Maintenance, Security (Lost & Found), and Care Services.

🔐 Role-Based Access: Distinct interfaces and permissions for Owners, Tenants, Security Managers, and Admins.

☁️ Robust Backend: Powered by Supabase (Docker/Edge Functions) for real-time chat, secure auth, and media handling via Google Drive.

# MainScreen

## Sign Up/Sign in

* sign in using Email address or using Google Account
* members selects a community from list to join 
* - upload proof of Resident (owner - rental) 
* - building number and apartment number
* - choosing Role as resident or Manager

## Homepage
**AppBar**
* dropdown Menu to Join other community where you can switch between then
* - Needs a fix ( asking the member to enter Residential info to be recorde for verification at this new compound)

**Services**
* selecting one of the services
* - **Maintenance report** : users can report there issues (Plumbing - elevator - ex..)
* - **Security** 
*  - -  File report (something happen ) 
*  - -  Lost and found section : report something lost - check lost and found posts made by security 
* - **Care service**
* - - Request a service (cleaning your apartment)
* - - Report something wrong with building cleaning 

**Announcements** [To be added]
* admins announcements
* Managers announcements (security)
* every role is labeled 

**GeneralChat - Social**

**GeneralChat**
*  BrainStorming :dedicated section for polls separated from chat ,  where members can disuse important Topics which can help with decision-making.
* every member is labeled with there building number and there apartment which helps for making you feel more connected and recognizable 
* electronic signature collection [future plans]
* members can report unappropriated or against community roles message so Admins can view this reports to take the appropriate action
* Admins can close chat temp.
* Admins can use add keywords to filter chat - activating isolate messages for review [future plans]

**Social**
* creating posts facebook like 

## AdminDashboard

**User Management**
* admins can see all users information and edit them
* view a score system from based on reports filed against them 
* isolate member messages that isn't visible to public (Monitoring suspicious member) only visible to admins to approve to go public or not [future plans]
* update members roles

**Verification Requests**
* Approve - delcine Newly created account 
* send phone-number OTP [future plans]
* contact user for additional information via whatsapp

**Users Reports**
* view chat reports
* ban - isolate chat

## Profile
**owners**
* can place his apartment for rental 
* Manage there rental (Activating , deactivating) accounts under there apartment


## Marketplace [future plans]
**oneTap**
SideNav
* Broker Market
* Manpower Market




type User record {
     int id?;
     string username?;
     string firstName?;
     string lastName?;
     string email?;
     string phone?;
};

type Error record { 
     int code;
     string message;
};
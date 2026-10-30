CREATE TABLE Campaigns (
    CampaignID INT IDENTITY(1,1) PRIMARY KEY,
    AgentID INT NOT NULL,
    CampaignName VARCHAR(150) NOT NULL,
    Channel VARCHAR(50) NOT NULL,
    Budget DECIMAL(10,2) NOT NULL
);
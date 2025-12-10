return {
    Name = "Default-Package", -- The name of your Package spaces not allowed
    Version = "1.0.0", -- Version usually X.X.X
    Author = "Me", -- Your name or what you go by
    Description = "The default package for everything", -- A brief description of your Package
    Type = "Both", -- Server | Client | Both

    Dependencies = {}, -- Packages this Package requires
    Optional_Dependencies = {}, -- Packages this Package wants
    File_Dependencies = {} -- Required Files
}

-- Custom items odds for use while PairMod is active.
-- Lessens the amount of attacking items appear near top ranks, gives first a chance at sneaker.
-- Hopefully we don't become MineMod again...
rawset(_G, "PAIRMOD_CUSTOM_ITEM_ODDS", {
    [KITEM_SNEAKER] =         {1, 1, 2, 2, 0, 0, 0, 0, 0, 0},
    [KITEM_ROCKETSNEAKER] =   {0, 0, 0, 0, 0, 0, 6, 2, 4, 0},
    [KITEM_INVINCIBILITY] =   {0, 0, 0, 0, 0, 0, 3, 3, 4, 0},
    [KITEM_BANANA] =          {0, 4, 0, 0, 0, 0, 0, 0, 0, 0},
    [KITEM_EGGMAN] =          {0, 5, 2, 0, 0, 0, 0, 0, 0, 0},
    [KITEM_ORBINAUT] =        {0, 9, 2, 0, 0, 0, 0, 0, 0, 0},
    [KITEM_JAWZ] =            {0, 0, 2, 0, 0, 0, 0, 0, 0, 0},
    [KITEM_MINE] =            {0, 0, 1, 1, 1, 1, 0, 0, 0, 0},
    [KITEM_BALLHOG] =         {0, 0, 0, 0, 1, 1, 0, 0, 0, 0},
    [KITEM_SPB] =             {0, 0, 0, 2, 1, 1, 1, 0, 0, 1},
    [KITEM_GROW] =            {0, 0, 0, 0, 0, 0, 2, 3, 1, 0},
    [KITEM_SHRINK] =          {0, 0, 0, 0, 0, 0, 1, 1, 0, 0},
    [KITEM_THUNDERSHIELD] =   {0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
    [KITEM_HYUDORO] =         {0, 0, 0, 0, 1, 1, 2, 2, 0, 0},
    [KITEM_POGOSPRING] =      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    [KITEM_KITCHENSINK] =     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    [KRITEM_TRIPLESNEAKER] =  {0, 0, 0, 0, 1, 1, 0, 0, 0, 0},
    [KRITEM_TRIPLEBANANA] =   {0, 0, 0, 2, 0, 0, 0, 0, 0, 0},
    [KRITEM_TENFOLDBANANA] =  {0, 0, 0, 0, 1, 0, 0, 0, 0, 0},
    [KRITEM_TRIPLEORBINAUT] = {0, 0, 0, 2, 2, 2, 2, 0, 0, 0},
    [KRITEM_QUADORBINAUT] =   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    [KRITEM_DUALJAWZ] =       {0, 0, 0, 2, 2, 2, 2, 0, 0, 0},
})

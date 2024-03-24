local playerMeta = FindMetaTable("Player")

function playerMeta:RepairBarricade()
    self.LastBarricade:Use(self, self, USE_ON, 1)
end

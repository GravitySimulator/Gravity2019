class PlanetAssets {
  Planet pl ;
  PlanetAssets(Planet myplanet) {
    this.pl = myplanet ;
  }
  void showPlanetAt_0_0() {
    pushMatrix();
    scale(pl.size, pl.size, pl.size);
    sphere(.5);
    popMatrix();
  }
}

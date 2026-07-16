SELECT hd.hd_buy_potential, COUNT(*) AS cnt FROM household_demographics hd JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk GROUP BY hd.hd_buy_potential

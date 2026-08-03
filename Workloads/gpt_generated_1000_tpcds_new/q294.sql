(
  SELECT
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
    SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
    AVG(cs.cs_list_price) AS avg_list_price,
    MIN(sr.sr_fee) AS min_fee,
    MAX(sr.sr_store_credit) AS max_store_credit
  FROM catalog_sales cs
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN store_returns sr
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_income_band_sk = 5
    AND hd.hd_buy_potential = '>10000'
    AND hd.hd_dep_count >= 2
    AND cs.cs_list_price > 50.00
    AND cs.cs_ship_addr_sk = 572777
    AND cs.cs_net_paid_inc_ship BETWEEN 2000 AND 6000
    AND sr.sr_fee > 40.00
    AND sr.sr_store_credit < 250.00
  GROUP BY hd.hd_income_band_sk, hd.hd_buy_potential
)
UNION
(
  SELECT
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
    SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
    AVG(cs.cs_list_price) AS avg_list_price,
    MIN(sr.sr_fee) AS min_fee,
    MAX(sr.sr_store_credit) AS max_store_credit
  FROM catalog_sales cs
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN store_returns sr
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_income_band_sk = 12
    AND hd.hd_buy_potential = '1001-5000'
    AND hd.hd_dep_count <= 5
    AND cs.cs_list_price > 80.00
    AND cs.cs_ship_addr_sk = 3240382
    AND cs.cs_net_paid_inc_ship BETWEEN 3000 AND 7000
    AND sr.sr_fee > 50.00
    AND sr.sr_store_credit < 200.00
  GROUP BY hd.hd_income_band_sk, hd.hd_buy_potential
)
INTERSECT
(
  SELECT
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
    SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
    AVG(cs.cs_list_price) AS avg_list_price,
    MIN(sr.sr_fee) AS min_fee,
    MAX(sr.sr_store_credit) AS max_store_credit
  FROM catalog_sales cs
  JOIN household_demographics hd
    ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
  JOIN store_returns sr
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_income_band_sk IN (5, 12)
    AND hd.hd_buy_potential IN ('>10000', '1001-5000')
    AND hd.hd_vehicle_count > 0
    AND cs.cs_list_price > 60.00
    AND cs.cs_ship_addr_sk IN (572777, 3240382)
    AND cs.cs_net_paid_inc_ship BETWEEN 2500 AND 6500
    AND sr.sr_fee > 45.00
    AND sr.sr_store_credit < 260.00
  GROUP BY hd.hd_income_band_sk, hd.hd_buy_potential
)
ORDER BY total_net_paid DESC
LIMIT 100

WITH cat_sales AS (
   SELECT
     cs.cs_order_number AS order_number,
     cs.cs_net_paid AS net_paid,
     cs.cs_quantity AS quantity,
     cc.cc_name AS call_center_name,
     p_cs.p_promo_name AS promo_name,
     hd_bill.hd_buy_potential AS buy_potential,
     ib_bill.ib_lower_bound AS income_lower,
     ib_bill.ib_upper_bound AS income_upper,
     cs.cs_sold_date_sk AS sold_date_sk
   FROM tpcds.catalog_sales cs
   JOIN tpcds.call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.promotion p_cs
     ON cs.cs_promo_sk = p_cs.p_promo_sk
   JOIN tpcds.household_demographics hd_bill
     ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN tpcds.household_demographics hd_ship
     ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN tpcds.income_band ib_bill
     ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
   JOIN tpcds.income_band ib_ship
     ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
   WHERE NOT EXISTS (
     SELECT 1
     FROM tpcds.promotion p_excl
     WHERE p_excl.p_promo_sk = cs.cs_promo_sk
       AND p_excl.p_channel_radio = 'Y'
   )
),
web_sales AS (
   SELECT
     ws.ws_order_number AS order_number,
     ws.ws_net_paid AS net_paid,
     ws.ws_quantity AS quantity,
     p_ws.p_promo_name AS promo_name,
     hd_ws_bill.hd_buy_potential AS buy_potential,
     ib_ws_bill.ib_lower_bound AS income_lower,
     ib_ws_bill.ib_upper_bound AS income_upper,
     ws.ws_sold_date_sk AS sold_date_sk
   FROM tpcds.web_sales ws
   JOIN tpcds.promotion p_ws
     ON ws.ws_promo_sk = p_ws.p_promo_sk
   JOIN tpcds.household_demographics hd_ws_bill
     ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
   JOIN tpcds.household_demographics hd_ws_ship
     ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
   JOIN tpcds.income_band ib_ws_bill
     ON hd_ws_bill.hd_income_band_sk = ib_ws_bill.ib_income_band_sk
   JOIN tpcds.income_band ib_ws_ship
     ON hd_ws_ship.hd_income_band_sk = ib_ws_ship.ib_income_band_sk
   WHERE NOT EXISTS (
     SELECT 1
     FROM tpcds.promotion p_excl
     WHERE p_excl.p_promo_sk = ws.ws_promo_sk
       AND p_excl.p_channel_event = 'Y'
   )
),
combined AS (
   SELECT
     order_number,
     net_paid,
     quantity,
     call_center_name,
     promo_name,
     buy_potential,
     sold_date_sk,
     'Catalog' AS sales_channel
   FROM cat_sales
   UNION ALL
   SELECT
     order_number,
     net_paid,
     quantity,
     NULL AS call_center_name,
     promo_name,
     buy_potential,
     sold_date_sk,
     'Web' AS sales_channel
   FROM web_sales
),
agg AS (
   SELECT
     sales_channel,
     call_center_name,
     promo_name,
     buy_potential,
     SUM(net_paid) AS total_net_paid,
     SUM(quantity) AS total_quantity
   FROM combined
   GROUP BY ROLLUP (sales_channel, call_center_name, promo_name, buy_potential)
)
SELECT
   sales_channel,
   call_center_name,
   promo_name,
   buy_potential,
   total_net_paid,
   total_quantity,
   ROW_NUMBER() OVER (PARTITION BY sales_channel ORDER BY total_net_paid DESC) AS sales_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100

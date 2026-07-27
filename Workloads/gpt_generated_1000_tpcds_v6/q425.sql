WITH buyer_sales AS (
   SELECT
       ws.ws_order_number,
       ws.ws_net_paid_inc_tax,
       CASE
           WHEN ws.ws_net_profit > 1000 THEN 'High'
           WHEN ws.ws_net_profit > 0 THEN 'Medium'
           ELSE 'Low'
       END AS profit_category,
       hd.hd_buy_potential,
       wp.wp_url
   FROM tpcds.web_sales ws
   JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE hd.hd_buy_potential = '>10000'
     AND ib.ib_upper_bound > 100000
     AND EXISTS (
         SELECT 1 FROM tpcds.web_page wp2
         WHERE wp2.wp_web_page_sk = ws.ws_web_page_sk
           AND wp2.wp_type = 'product'
     )
),
ship_sales AS (
   SELECT
       ws.ws_order_number,
       ws.ws_net_paid_inc_tax,
       CASE
           WHEN ws.ws_net_profit > 500 THEN 'High'
           WHEN ws.ws_net_profit > 0 THEN 'Medium'
           ELSE 'Low'
       END AS profit_category,
       hd.hd_buy_potential,
       wp.wp_url
   FROM tpcds.web_sales ws
   JOIN tpcds.household_demographics hd
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE hd.hd_vehicle_count = 0
     AND ib.ib_lower_bound <= 50000
     AND ws.ws_net_paid_inc_tax > (
         SELECT AVG(ws2.ws_net_paid_inc_tax)
         FROM tpcds.web_sales ws2
     )
)
SELECT
    order_number,
    net_paid_inc_tax,
    profit_category,
    buy_potential,
    url
FROM (
    SELECT
        ws_order_number AS order_number,
        ws_net_paid_inc_tax AS net_paid_inc_tax,
        profit_category,
        hd_buy_potential AS buy_potential,
        wp_url AS url
    FROM buyer_sales
    UNION ALL
    SELECT
        ws_order_number AS order_number,
        ws_net_paid_inc_tax AS net_paid_inc_tax,
        profit_category,
        hd_buy_potential AS buy_potential,
        wp_url AS url
    FROM ship_sales
) combined
ORDER BY net_paid_inc_tax DESC
LIMIT 100

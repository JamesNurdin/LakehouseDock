WITH catalog_agg AS (
   SELECT
      'catalog' AS sales_channel,
      hd_bill.hd_buy_potential AS buy_potential,
      SUM(cs.cs_net_paid)      AS total_net_paid,
      SUM(cs.cs_net_profit)    AS total_profit,
      COUNT(DISTINCT cs.cs_order_number) AS order_cnt
   FROM catalog_sales cs
   JOIN customer c_bill
     ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
   JOIN customer c_ship
     ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
   JOIN household_demographics hd_bill
     ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship
     ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   LEFT JOIN catalog_returns cr
     ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk      = cr.cr_item_sk
   LEFT JOIN customer c_refunded
     ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
   LEFT JOIN household_demographics hd_refunded
     ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
   WHERE NOT EXISTS (
            SELECT 1 FROM web_sales ws_chk
            WHERE ws_chk.ws_order_number = cs.cs_order_number
         )
     AND cs.cs_net_paid > 0
   GROUP BY hd_bill.hd_buy_potential
),
web_agg AS (
   SELECT
      'web' AS sales_channel,
      hd_bill.hd_buy_potential AS buy_potential,
      SUM(ws.ws_net_paid)      AS total_net_paid,
      SUM(ws.ws_net_profit)    AS total_profit,
      COUNT(DISTINCT ws.ws_order_number) AS order_cnt
   FROM web_sales ws
   JOIN customer c_bill
     ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
   JOIN customer c_ship
     ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
   JOIN household_demographics hd_bill
     ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship
     ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
   LEFT JOIN web_returns wr
     ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk      = wr.wr_item_sk
   LEFT JOIN customer c_refunded
     ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
   LEFT JOIN household_demographics hd_refunded
     ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
   WHERE NOT EXISTS (
            SELECT 1 FROM catalog_sales cs_chk
            WHERE cs_chk.cs_order_number = ws.ws_order_number
         )
     AND ws.ws_net_paid > 0
   GROUP BY hd_bill.hd_buy_potential
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY sales_channel, buy_potential
LIMIT 100

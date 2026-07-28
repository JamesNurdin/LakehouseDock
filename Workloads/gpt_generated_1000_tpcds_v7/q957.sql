WITH catalog_sub AS (
   SELECT
       cs.cs_item_sk AS item_sk,
       cs.cs_sold_date_sk AS sold_date_sk,
       cs.cs_net_profit AS net_profit,
       CAST('catalog' AS varchar) AS sales_channel
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE i.i_color = 'pink'
     AND w.w_state = 'CA'
     AND cs.cs_quantity > 5
     AND cs.cs_net_profit > 0
),
web_sub AS (
   SELECT
       ws.ws_item_sk AS item_sk,
       ws.ws_sold_date_sk AS sold_date_sk,
       ws.ws_net_profit AS net_profit,
       CAST('web' AS varchar) AS sales_channel
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   WHERE i.i_color = 'purple'
     AND hd.hd_income_band_sk = 7
     AND ws.ws_quantity > 3
     AND ws.ws_net_profit > 0
)
SELECT *
FROM catalog_sub
UNION ALL
SELECT *
FROM web_sub
ORDER BY net_profit DESC
LIMIT 100

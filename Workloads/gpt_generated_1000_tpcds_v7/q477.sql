/*
Goal: Identify the highest‑priced products sold on each web site for customers in high‑income bands, rank product sales within each site and rank total sales within each warehouse, and show a 5‑order moving total of sales amount.
*/
SELECT
  wsit.web_name,
  wh.w_warehouse_id,
  i.i_product_name,
  ws.ws_sales_price,
  ws.ws_quantity,
  ws.ws_ext_sales_price,
  ws.ws_net_profit,
  CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Medium' END AS income_band_category,
  ROW_NUMBER() OVER (PARTITION BY wsit.web_name ORDER BY ws.ws_sales_price DESC) AS product_rank_in_site,
  RANK() OVER (PARTITION BY wh.w_warehouse_id ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank_in_warehouse,
  SUM(ws.ws_ext_sales_price) OVER (
        PARTITION BY wsit.web_name
        ORDER BY ws.ws_order_number
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
      ) AS moving_5order_sum
FROM web_sales ws
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN warehouse wh
  ON ws.ws_warehouse_sk = wh.w_warehouse_sk
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE wh.w_zip IN ('58828', '38048')
  AND ib.ib_lower_bound >= 50000
  AND ws.ws_sales_price > 20
  AND wsit.web_state = 'CA'
ORDER BY wsit.web_name, product_rank_in_site
LIMIT 100

WITH store_data AS (
  SELECT i.i_item_id,
         i.i_item_desc,
         SUM(ss.ss_net_paid) AS total_net_paid,
         'store' AS sales_channel
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE td.t_hour BETWEEN 9 AND 17
    AND ss.ss_ext_discount_amt < 50
    AND ib.ib_upper_bound >= 50000
    AND EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND p.p_discount_active = 'Y')
  GROUP BY i.i_item_id, i.i_item_desc
  HAVING SUM(ss.ss_net_paid) > 1000
),
web_data AS (
  SELECT i.i_item_id,
         i.i_item_desc,
         SUM(ws.ws_net_paid) AS total_net_paid,
         'web' AS sales_channel
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE td.t_hour BETWEEN 9 AND 17
    AND ws.ws_ext_discount_amt < 50
    AND ib.ib_upper_bound >= 50000
    AND EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND p.p_discount_active = 'Y')
  GROUP BY i.i_item_id, i.i_item_desc
  HAVING SUM(ws.ws_net_paid) > 1000
),
combined AS (
  SELECT * FROM store_data
  UNION
  SELECT * FROM web_data
)
SELECT i_item_id,
       i_item_desc,
       total_net_paid,
       sales_channel,
       ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn
FROM combined
ORDER BY total_net_paid DESC, sales_channel
LIMIT 100

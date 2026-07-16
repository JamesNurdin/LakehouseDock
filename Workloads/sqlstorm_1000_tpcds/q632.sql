WITH sales_all AS (
  SELECT 
    d.d_year,
    'store' AS channel,
    ss.ss_ticket_number AS transaction_id,
    ss.ss_item_sk AS item_sk,
    d.d_date_sk AS date_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    s.s_store_name AS location_name,
    i.i_category AS item_category,
    i.i_brand AS item_brand,
    p.p_promo_name AS promo_name,
    t.t_hour AS hour_of_day
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE d.d_year BETWEEN 1997 AND 1998
  UNION ALL
  SELECT 
    d.d_year,
    'catalog' AS channel,
    cs.cs_order_number AS transaction_id,
    cs.cs_item_sk AS item_sk,
    d.d_date_sk AS date_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    cc.cc_name AS location_name,
    i.i_category AS item_category,
    i.i_brand AS item_brand,
    p.p_promo_name AS promo_name,
    t.t_hour AS hour_of_day
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE d.d_year BETWEEN 1997 AND 1998
  UNION ALL
  SELECT 
    d.d_year,
    'web' AS channel,
    ws.ws_order_number AS transaction_id,
    ws.ws_item_sk AS item_sk,
    d.d_date_sk AS date_sk,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    wp.wp_url AS location_name,
    i.i_category AS item_category,
    i.i_brand AS item_brand,
    p.p_promo_name AS promo_name,
    t.t_hour AS hour_of_day
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE d.d_year BETWEEN 1997 AND 1998
),
returns_all AS (
  SELECT 
    d.d_year,
    'store' AS channel,
    sr.sr_ticket_number AS transaction_id,
    sr.sr_item_sk AS item_sk,
    d.d_date_sk AS date_sk,
    sr.sr_return_quantity AS quantity,
    (sr.sr_return_amt + sr.sr_return_tax + sr.sr_fee + sr.sr_return_ship_cost) AS return_amount,
    sr.sr_net_loss AS net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  UNION ALL
  SELECT 
    d.d_year,
    'catalog' AS channel,
    cr.cr_order_number AS transaction_id,
    cr.cr_item_sk AS item_sk,
    d.d_date_sk AS date_sk,
    cr.cr_return_quantity AS quantity,
    (cr.cr_return_amount + cr.cr_return_tax + cr.cr_fee + cr.cr_return_ship_cost) AS return_amount,
    cr.cr_net_loss AS net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  UNION ALL
  SELECT 
    d.d_year,
    'web' AS channel,
    wr.wr_order_number AS transaction_id,
    wr.wr_item_sk AS item_sk,
    d.d_date_sk AS date_sk,
    wr.wr_return_quantity AS quantity,
    (wr.wr_return_amt + wr.wr_return_tax + wr.wr_fee + wr.wr_return_ship_cost) AS return_amount,
    wr.wr_net_loss AS net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
)

SELECT 
  s.d_year,
  s.channel,
  s.item_category,
  s.item_brand,
  SUM(s.net_paid) AS total_sales,
  SUM(s.net_profit) AS total_profit,
  COALESCE(SUM(r.return_amount), 0) AS total_return_amount,
  SUM(s.net_profit) - COALESCE(SUM(r.net_loss), 0) AS net_profit_after_returns,
  COUNT(DISTINCT s.transaction_id) AS distinct_transactions,
  AVG(s.quantity) AS avg_quantity_per_transaction,
  MAX(s.net_paid) AS max_transaction_value,
  MIN(s.net_paid) AS min_transaction_value,
  COUNT(*) AS total_sales_transactions,
  SUM(CASE WHEN s.hour_of_day BETWEEN 9 AND 17 THEN s.net_paid ELSE 0 END) AS sales_business_hours,
  SUM(CASE WHEN s.hour_of_day NOT BETWEEN 9 AND 17 THEN s.net_paid ELSE 0 END) AS sales_off_hours
FROM sales_all s
LEFT JOIN returns_all r 
  ON s.channel = r.channel 
  AND s.transaction_id = r.transaction_id 
  AND s.item_sk = r.item_sk
WHERE s.d_year IS NOT NULL
GROUP BY 
  s.d_year,
  s.channel,
  s.item_category,
  s.item_brand
ORDER BY 
  s.d_year,
  s.channel,
  total_sales DESC
LIMIT 100

WITH
  high_value_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_net_paid > 5000
      AND regexp_like(p.p_channel_details, '.*common.*')
      AND p.p_channel_catalog LIKE 'N%'
  ),
  large_quantity_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_quantity >= 10
      AND t.t_sub_shift = 'night'
  ),
  intersected_orders AS (
    SELECT ws_order_number FROM high_value_orders
    INTERSECT
    SELECT ws_order_number FROM large_quantity_orders
  )
SELECT
  p.p_promo_name,
  CONCAT(p.p_promo_name, ' - ', t.t_shift) AS promo_shift,
  MAX(REGEXP_EXTRACT(p.p_channel_details, '(common|Offences)', 1)) AS extracted_term,
  COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
  SUM(ws.ws_net_paid) AS total_net_paid,
  ROUND(AVG(ws.ws_ext_discount_amt), 2) AS avg_discount,
  (SELECT AVG(ws_ext_discount_amt) FROM web_sales) AS overall_avg_discount,
  CASE
    WHEN SUM(ws.ws_net_paid) > 100000 THEN 'High'
    WHEN SUM(ws.ws_net_paid) > 50000 THEN 'Medium'
    ELSE 'Low'
  END AS revenue_class
FROM web_sales ws
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
WHERE ws.ws_order_number IN (SELECT ws_order_number FROM intersected_orders)
  AND ws.ws_ext_discount_amt > (SELECT AVG(ws_ext_discount_amt) FROM web_sales)
  AND regexp_like(p.p_channel_details, '.*[A-Za-z]{5,}.*')
  AND p.p_channel_catalog LIKE 'N%'
  AND EXISTS (
    SELECT 1
    FROM promotion p3
    WHERE p3.p_promo_sk = ws.ws_promo_sk
      AND regexp_like(p3.p_channel_details, 'common')
  )
GROUP BY
  p.p_promo_name,
  CONCAT(p.p_promo_name, ' - ', t.t_shift)
ORDER BY total_net_paid DESC
LIMIT 100

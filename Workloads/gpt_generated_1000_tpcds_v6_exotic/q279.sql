WITH web_data AS (
  SELECT
    i.i_category,
    i.i_product_name,
    ws.ws_net_paid AS net_paid,
    ws.ws_sold_time_sk,
    ws.ws_order_number,
    CASE WHEN regexp_like(i.i_product_name, '^.*[0-9]{3}.*$') THEN 1 ELSE 0 END AS has_three_digit_code,
    CONCAT(i.i_brand, ' - ', i.i_product_name) AS brand_product,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ws.ws_net_paid DESC) AS rn
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE i.i_color LIKE '%Red%'
    AND regexp_like(i.i_product_name, '.*[A-Z]{2}.*')
    AND p.p_promo_name LIKE '%Clearance%'
),
store_data AS (
  SELECT
    i.i_category,
    i.i_product_name,
    ss.ss_net_paid AS net_paid,
    ss.ss_sold_time_sk,
    ss.ss_ticket_number AS order_number,
    CASE WHEN regexp_like(i.i_product_name, '^.*[0-9]{3}.*$') THEN 1 ELSE 0 END AS has_three_digit_code,
    CONCAT(i.i_brand, ' - ', i.i_product_name) AS brand_product,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss.ss_net_paid DESC) AS rn
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE i.i_color LIKE '%Red%'
    AND regexp_like(i.i_product_name, '.*[A-Z]{2}.*')
    AND p.p_promo_name LIKE '%Clearance%'
)
SELECT
  category,
  SUM(net_paid) AS total_net_paid,
  AVG(net_paid) AS avg_net_paid,
  SUM(has_three_digit_code) AS items_with_three_digit_code,
  MAX(rn) AS max_rank
FROM (
  SELECT i_category AS category,
         net_paid,
         has_three_digit_code,
         rn
  FROM web_data
  UNION ALL
  SELECT i_category AS category,
         net_paid,
         has_three_digit_code,
         rn
  FROM store_data
) combined
GROUP BY category
ORDER BY total_net_paid DESC
LIMIT 20

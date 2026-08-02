SELECT
    s.s_store_id,
    concat(s.s_store_name, ' - ', substring(ca.ca_city, 1, 5)) AS store_label,
    i.i_category,
    regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_code,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promo_count
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND d.d_dow BETWEEN 2 AND 6
  AND t.t_meal_time = 'breakfast'
  AND regexp_like(i.i_item_desc, '(?i)red')
  AND s.s_store_name LIKE '%Store%'
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    substring(ca.ca_city, 1, 5),
    i.i_category,
    regexp_extract(p.p_promo_name, '(\\d+)', 1)
ORDER BY total_net_profit DESC
OFFSET 0 ROWS
LIMIT 100

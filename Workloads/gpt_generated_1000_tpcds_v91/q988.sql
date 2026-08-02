SELECT
    CONCAT(s.s_store_name, ' - ', i.i_category) AS store_category,
    s.s_store_name,
    i.i_category,
    i.i_brand,
    substr(i.i_item_desc, 1, 15) AS short_item_desc,
    REGEXP_EXTRACT(i.i_item_desc, '([0-9]+)', 1) AS numeric_part_of_desc,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_profit ELSE 0 END) AS positive_profit_sum,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_ticket_count,
    COUNT(DISTINCT ca.ca_zip) AS distinct_customer_zip_count
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE s.s_store_name LIKE '%Market%'
  AND REGEXP_LIKE(i.i_item_desc, '[0-9]{3}')
GROUP BY s.s_store_name, i.i_category, i.i_brand, i.i_item_desc
ORDER BY total_net_profit DESC
OFFSET 0
LIMIT 100

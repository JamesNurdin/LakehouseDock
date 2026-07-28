WITH sales_filtered AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    s.s_store_name AS store_name,
    ca.ca_city AS city,
    ss.ss_net_profit AS net_profit,
    ss.ss_ticket_number AS ticket_number
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2002
    AND s.s_store_name LIKE 'A%'
    AND regexp_like(p.p_promo_name, 'Discount')
    AND regexp_like(ca.ca_city, 'York')
)
SELECT
  store_name,
  city,
  SUM(net_profit) AS total_profit,
  COUNT(DISTINCT ticket_number) AS txn_count,
  CONCAT(store_name, ' - ', city) AS store_label,
  SUBSTRING(city, 1, 3) AS city_prefix
FROM sales_filtered
GROUP BY store_name, city
HAVING SUM(net_profit) > (
  SELECT AVG(store_total) FROM (
    SELECT SUM(net_profit) AS store_total
    FROM sales_filtered
    GROUP BY store_name, city
  ) t
)
ORDER BY total_profit DESC
LIMIT 100

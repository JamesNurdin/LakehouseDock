WITH store_profit_by_year AS (
   SELECT s.s_store_name,
          d.d_year,
          SUM(ss.ss_net_profit) AS total_net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   GROUP BY s.s_store_name, d.d_year
)

SELECT
    'Store' AS source,
    s.s_store_name AS name,
    d.d_year AS year,
    SUM(ss.ss_net_paid) AS total_sales,
    COUNT(*) AS transaction_count
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE p.p_discount_active = 'Y'
  AND p.p_cost < (SELECT AVG(p2.p_cost) FROM promotion p2)
  AND d.d_year BETWEEN 2000 AND 2002
  AND EXISTS (
        SELECT 1
        FROM store_profit_by_year sp
        WHERE sp.s_store_name = s.s_store_name
          AND sp.d_year = d.d_year
          AND sp.total_net_profit > 10000
    )
GROUP BY s.s_store_name, d.d_year

UNION ALL

SELECT
    'Catalog' AS source,
    c.c_customer_id AS name,
    d.d_year AS year,
    SUM(cs.cs_net_paid) AS total_sales,
    COUNT(*) AS transaction_count
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
WHERE p.p_discount_active = 'Y'
  AND p.p_cost < (SELECT AVG(p2.p_cost) FROM promotion p2)
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY c.c_customer_id, d.d_year

ORDER BY source, name, year
LIMIT 100

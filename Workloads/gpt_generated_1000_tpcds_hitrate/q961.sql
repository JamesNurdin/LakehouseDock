WITH filtered_promotions AS (
    SELECT p_promo_sk, p_promo_name, p_cost
    FROM promotion
    WHERE p_discount_active = 'Y'
      AND p_cost > 1000
)
SELECT
    cs.cs_item_sk          AS item_sk,
    ss.ss_store_sk         AS store_sk,
    d_cs.d_year            AS sold_year,
    d_ss.d_year            AS store_year,
    SUM(cs.cs_ext_sales_price)                                   AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price)                                   AS total_store_sales,
    COUNT(DISTINCT cs.cs_order_number)                           AS distinct_catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number)                          AS distinct_store_tickets,
    SUM(CASE WHEN cs.cs_ext_discount_amt > 0 THEN 1 ELSE 0 END)  AS catalog_discounted_orders,
    MAX(cs.cs_net_profit)                                        AS max_catalog_profit,
    MIN(ss.ss_net_profit)                                        AS min_store_profit,
    (SELECT MAX(p_cost) FROM promotion)                          AS max_promo_cost,
    MAX(l.store_item_sales)                                      AS max_store_item_sales,
    COUNT(*)                                                      AS rows_in_group
FROM catalog_sales cs
JOIN filtered_promotions p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN store_sales ss
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_cs
  ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs
  ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN date_dim d_ss
  ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss
  ON ss.ss_sold_time_sk = t_ss.t_time_sk
LEFT JOIN LATERAL (
    SELECT SUM(ss2.ss_ext_sales_price) AS store_item_sales
    FROM store_sales ss2
    WHERE ss2.ss_item_sk = cs.cs_item_sk
) l ON TRUE
WHERE d_cs.d_year = 2001
  AND t_cs.t_hour BETWEEN 10 AND 14
  AND ss.ss_net_paid > 100
  AND cs.cs_wholesale_cost < (SELECT MIN(p_cost) FROM promotion)
GROUP BY GROUPING SETS (
    (cs.cs_item_sk, d_cs.d_year),
    (ss.ss_store_sk, d_ss.d_year),
    ()
)
ORDER BY total_catalog_sales DESC
LIMIT 100

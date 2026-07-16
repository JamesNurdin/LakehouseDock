SELECT
    s.s_city,
    r.r_reason_desc,
    cs.cs_sold_date_sk AS sold_date_sk,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
    RANK() OVER (PARTITION BY s.s_city ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
FROM catalog_sales cs
JOIN store s
  ON cs.cs_sold_date_sk = s.s_closed_date_sk
JOIN reason r
  ON cs.cs_promo_sk = r.r_reason_sk
WHERE cs.cs_ext_ship_cost > 200.00
  AND cs.cs_warehouse_sk IN (4, 10, 11)
  AND s.s_state = 'CA'
  AND r.r_reason_desc LIKE '%Promotion%'
GROUP BY
    s.s_city,
    r.r_reason_desc,
    cs.cs_sold_date_sk
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100

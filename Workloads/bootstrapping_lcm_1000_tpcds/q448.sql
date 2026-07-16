SELECT
    s.s_store_id,
    p.p_promo_name,
    d_sold.d_year AS sale_year,
    CAST(((d_sold.d_month_seq - 1) / 3) + 1 AS integer) AS sale_quarter,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(cs.cs_net_profit) = 0 THEN NULL
        ELSE SUM(p.p_cost) / SUM(cs.cs_net_profit)
    END AS promo_cost_to_profit_ratio,
    AVG(date_diff('day', d_promo_start.d_date, d_promo_end.d_date)) AS avg_promo_duration_days,
    MAX(d_ship.d_date) AS max_ship_date,
    MIN(d_store_closed.d_date) AS min_store_closed_date
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_store_closed
    ON cs.cs_sold_date_sk = d_store_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year = 2022
  AND d_ship.d_month_seq BETWEEN 1 AND 12
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_id,
    p.p_promo_name,
    d_sold.d_year,
    CAST(((d_sold.d_month_seq - 1) / 3) + 1 AS integer)
HAVING COUNT(*) > 10
ORDER BY total_net_paid DESC
LIMIT 100

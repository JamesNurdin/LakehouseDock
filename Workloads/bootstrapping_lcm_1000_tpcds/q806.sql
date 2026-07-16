SELECT
    s.s_store_name,
    w.w_warehouse_name,
    d_sold.d_current_month,
    p.p_promo_name,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    ROUND(SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_ext_sales_price), 0), 4) AS profit_margin,
    SUM(p.p_cost) AS total_promo_cost,
    ROUND(SUM(p.p_cost) / NULLIF(SUM(cs.cs_net_profit), 0), 4) AS promo_cost_per_profit
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE cs.cs_quantity > 0
  AND d_sold.d_year = 2022
  AND cs.cs_net_paid > 0
  AND d_promo_start.d_date <= d_sold.d_date
  AND d_promo_end.d_date >= d_sold.d_date
GROUP BY
    s.s_store_name,
    w.w_warehouse_name,
    d_sold.d_current_month,
    p.p_promo_name
HAVING SUM(cs.cs_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100

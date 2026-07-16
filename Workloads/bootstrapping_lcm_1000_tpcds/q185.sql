SELECT
    d_sold.d_year AS year,
    d_sold.d_month_seq AS month_seq,
    p.p_promo_name,
    s.s_state,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_catalog_items,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_web_items,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(cs.cs_ext_discount_amt) + SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    (SUM(cs.cs_ext_discount_amt) + SUM(ws.ws_ext_discount_amt)) / NULLIF(SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price), 0) AS avg_discount_ratio,
    SUM(p.p_cost) AS total_promo_cost,
    date_diff('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) / NULLIF(SUM(p.p_cost), 0) AS promo_active_cost_ratio,
    SUM(cs.cs_net_paid) - SUM(ws.ws_net_paid) AS net_paid_diff
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
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
    AND ws.ws_ship_date_sk = d_ship.d_date_sk
    AND ws.ws_promo_sk = p.p_promo_sk
JOIN store s
    ON s.s_closed_date_sk = d_promo_end.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    s.s_state,
    d_promo_start.d_date,
    d_promo_end.d_date
HAVING SUM(cs.cs_net_profit) > 0
ORDER BY catalog_net_profit DESC
LIMIT 100

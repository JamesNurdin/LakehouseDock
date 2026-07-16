SELECT
    sold_date.d_year AS sale_year,
    sold_date.d_month_seq AS sale_month,
    p.p_promo_name,
    s.s_store_name,
    cc.cc_name,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_coupon_amt) AS avg_coupon_amt,
    AVG(ship_date.d_month_seq - sold_date.d_month_seq) AS avg_month_delay,
    MAX(cc_close_date.d_year) AS cc_close_year,
    MIN(promo_start_date.d_year) AS promo_start_year,
    MAX(promo_end_date.d_year) AS promo_end_year,
    MAX(s.s_city) AS store_city,
    MAX(cc.cc_city) AS call_center_city,
    SUM(cs.cs_net_profit) - MIN(p.p_cost) * COUNT(*) AS profit_minus_promo_cost
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim sold_date
    ON cs.cs_sold_date_sk = sold_date.d_date_sk
JOIN date_dim ship_date
    ON cs.cs_ship_date_sk = ship_date.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = sold_date.d_date_sk
JOIN date_dim cc_close_date
    ON cc.cc_closed_date_sk = cc_close_date.d_date_sk
JOIN date_dim promo_start_date
    ON p.p_start_date_sk = promo_start_date.d_date_sk
JOIN date_dim promo_end_date
    ON p.p_end_date_sk = promo_end_date.d_date_sk
WHERE cs.cs_net_paid > 0
GROUP BY ROLLUP (sold_date.d_year, sold_date.d_month_seq, p.p_promo_name, s.s_store_name, cc.cc_name)
HAVING SUM(cs.cs_net_paid) > 10000

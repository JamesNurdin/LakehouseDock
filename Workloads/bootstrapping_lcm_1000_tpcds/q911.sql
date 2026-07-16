SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_name,
    cc.cc_market_manager,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MAX(cs.cs_quantity) AS max_quantity_per_order,
    MIN(d_ship.d_date) AS earliest_ship_date,
    MAX(d_ship.d_date) AS latest_ship_date,
    d_p_start.d_date AS promo_start_date,
    d_p_end.d_date AS promo_end_date
FROM store s
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
WHERE d_sold.d_year = 2001
  AND s.s_country = 'United States'
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_name,
    cc.cc_market_manager,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_p_start.d_date,
    d_p_end.d_date
ORDER BY total_net_paid DESC
LIMIT 100

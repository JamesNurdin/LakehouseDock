SELECT
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_quarter_name AS quarter,
    p.p_promo_id,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
    AVG(hd.hd_income_band_sk) AS avg_income_band,
    AVG(hd.hd_vehicle_count) AS avg_vehicles,
    MIN(d_closure.d_date) AS store_closure_date,
    MIN(d_start.d_date) AS promo_start_date,
    MAX(d_end.d_date) AS promo_end_date
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_quarter_name,
    p.p_promo_id,
    p.p_promo_name
ORDER BY total_profit DESC
LIMIT 10

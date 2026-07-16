SELECT
    d_sold.d_year AS sold_year,
    d_store_closed.d_year AS store_closed_year,
    d_promo_start.d_month_seq AS promo_start_month_seq,
    d_promo_end.d_month_seq AS promo_end_month_seq,
    d_web_close.d_week_seq AS web_close_week_seq,
    s.s_state AS store_state,
    w.web_state AS web_state,
    CASE WHEN mod(d_sold.d_month_seq, 2) = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT p.p_promo_id) AS promo_count
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN web_site w
    ON w.web_open_date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN date_dim d_web_close
    ON w.web_close_date_sk = d_web_close.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2015 AND 2020
    AND s.s_state IS NOT NULL
    AND w.web_state = s.s_state
    AND p.p_discount_active = 'Y'
    AND ss.ss_quantity > 0
GROUP BY
    d_sold.d_year,
    d_store_closed.d_year,
    d_promo_start.d_month_seq,
    d_promo_end.d_month_seq,
    d_web_close.d_week_seq,
    s.s_state,
    w.web_state,
    CASE WHEN mod(d_sold.d_month_seq, 2) = 0 THEN 'EvenMonth' ELSE 'OddMonth' END
HAVING
    SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100

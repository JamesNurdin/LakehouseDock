SELECT
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    d.d_year,
    d.d_quarter_name,
    CASE
        WHEN d.d_date BETWEEN date_start.d_date AND date_end.d_date THEN 'Active'
        ELSE 'Inactive'
    END AS promo_status,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_returns
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN date_dim date_start
    ON p.p_start_date_sk = date_start.d_date_sk
JOIN date_dim date_end
    ON p.p_end_date_sk = date_end.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    d.d_year,
    d.d_quarter_name,
    CASE
        WHEN d.d_date BETWEEN date_start.d_date AND date_end.d_date THEN 'Active'
        ELSE 'Inactive'
    END
ORDER BY total_sales_amount DESC
LIMIT 100

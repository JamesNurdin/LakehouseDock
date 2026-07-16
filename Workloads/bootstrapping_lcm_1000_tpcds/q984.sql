SELECT
    cp.cp_catalog_page_number,
    cp.cp_type,
    p.p_promo_name,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fees,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(wr.wr_return_amt) / NULLIF(AVG(p.p_cost), 0) AS return_to_promo_cost_ratio,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter_label
FROM date_dim d
JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
WHERE cp.cp_start_date_sk = d.d_date_sk
  AND p.p_end_date_sk = d.d_date_sk
  AND d.d_year = 2022
GROUP BY
    cp.cp_catalog_page_number,
    cp.cp_type,
    p.p_promo_name,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END
HAVING COUNT(DISTINCT wr.wr_order_number) > 5
ORDER BY total_return_amount DESC
LIMIT 100

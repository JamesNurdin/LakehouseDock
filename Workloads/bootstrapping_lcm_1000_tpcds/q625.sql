SELECT
    s.s_store_id,
    s.s_city,
    d_wr.d_year,
    CASE
        WHEN d_wr.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_wr.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_wr.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    p.p_promo_id,
    p.p_promo_name,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date,
    AVG(p.p_cost) AS avg_promo_cost,
    CASE
        WHEN SUM(i.inv_quantity_on_hand) > 0 THEN SUM(wr.wr_return_amt) / SUM(i.inv_quantity_on_hand)
        ELSE NULL
    END AS return_to_inventory_ratio
FROM web_returns wr
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_wr.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_wr.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk <= d_wr.d_date_sk
   AND p.p_end_date_sk   >= d_wr.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    d_wr.d_year,
    CASE
        WHEN d_wr.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_wr.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_wr.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    p.p_promo_id,
    p.p_promo_name
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 100

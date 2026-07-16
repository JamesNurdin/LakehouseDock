SELECT
    dd.d_date,
    s.s_store_name,
    s.s_city,
    cp.cp_department,
    cp.cp_type,
    p.p_promo_name,
    p.p_discount_active,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_return_tax) AS total_return_tax,
    COUNT(wr.wr_order_number) AS total_orders,
    AVG(p.p_cost) AS avg_promo_cost
FROM web_returns AS wr
JOIN date_dim AS dd
    ON wr.wr_returned_date_sk = dd.d_date_sk
JOIN store AS s
    ON s.s_closed_date_sk = dd.d_date_sk
JOIN catalog_page AS cp
    ON cp.cp_start_date_sk = dd.d_date_sk
JOIN promotion AS p
    ON p.p_start_date_sk = dd.d_date_sk
WHERE dd.d_year = 2022
GROUP BY
    dd.d_date,
    s.s_store_name,
    s.s_city,
    cp.cp_department,
    cp.cp_type,
    p.p_promo_name,
    p.p_discount_active
ORDER BY total_return_amt DESC
LIMIT 100

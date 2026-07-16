SELECT
    s.s_store_id,
    s.s_city,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    d_end.d_year AS promo_end_year,
    p.p_promo_name,
    p.p_discount_active,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(ss.ss_net_paid) AS total_sales_net_paid,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    SUM(ss.ss_quantity) AS total_sales_quantity,
    AVG(p.p_cost) AS avg_promo_cost,
    ROUND((SUM(cr.cr_return_amount) / NULLIF(SUM(ss.ss_net_paid), 0)) * 100, 2) AS return_to_sales_pct
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_ret.d_date_sk
    AND ss.ss_store_sk = s.s_store_sk
    AND ss.ss_promo_sk = p.p_promo_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_end.d_year,
    p.p_promo_name,
    p.p_discount_active
HAVING
    SUM(cr.cr_return_amount) > 0
ORDER BY
    total_return_amount DESC
LIMIT 100

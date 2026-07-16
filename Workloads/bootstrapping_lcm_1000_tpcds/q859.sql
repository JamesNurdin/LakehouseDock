SELECT
    cc.cc_country,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS order_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_quantity,
    COUNT(DISTINCT cust.c_customer_sk) AS distinct_customers,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_return_quantity), 0) AS avg_return_amount_per_item,
    CASE
        WHEN SUM(cr.cr_return_amount) > 50000 THEN 'HIGH'
        WHEN SUM(cr.cr_return_amount) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_volume_category
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN customer cust
    ON cr.cr_refunded_customer_sk = cust.c_customer_sk
WHERE cc.cc_country IS NOT NULL
  AND s.s_state IS NOT NULL
  AND d.d_year BETWEEN 2000 AND 2022
GROUP BY cc.cc_country, s.s_state, d.d_year, d.d_month_seq
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY total_net_loss DESC
LIMIT 100

SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    r.r_reason_desc AS return_reason,
    d.d_year AS return_year,
    d.d_month_seq AS return_month_seq,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    COUNT(*) AS total_returns,
    AVG(hd_returning.hd_income_band_sk) AS avg_returning_income_band,
    AVG(hd_refunded.hd_income_band_sk) AS avg_refunded_income_band,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_items,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
WHERE d.d_year >= 2000
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    r.r_reason_desc,
    d.d_year,
    d.d_month_seq
ORDER BY total_net_loss DESC, return_year DESC, return_month_seq DESC

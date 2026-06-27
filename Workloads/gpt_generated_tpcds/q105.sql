-- Total net loss and return metrics by month, return reason, and ship mode for the year 2001
SELECT
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    sm.sm_type,
    SUM(cr.cr_net_loss)                AS total_net_loss,
    SUM(cr.cr_return_quantity)         AS total_return_quantity,
    AVG(cr.cr_return_amount)           AS avg_return_amount,
    SUM(cs.cs_ext_sales_price)         AS total_original_sales,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns cr
JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk      = cs.cs_item_sk
JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc, sm.sm_type
ORDER BY d.d_year, d.d_month_seq, total_net_loss DESC

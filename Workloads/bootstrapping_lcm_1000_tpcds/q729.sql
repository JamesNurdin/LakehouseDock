SELECT
    dr.d_year,
    dr.d_month_seq,
    s.s_store_id,
    s.s_city,
    CASE WHEN s.s_state = 'CA' THEN 'California' ELSE s.s_state END AS state_group,
    c_ret.c_customer_id AS returning_customer_id,
    c_ref.c_customer_id AS refunded_customer_id,
    COUNT(DISTINCT cr.cr_order_number) AS total_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN cr.cr_fee > 0 THEN cr.cr_fee ELSE 0 END) AS total_fees,
    ROUND(SUM(cr.cr_net_loss) / NULLIF(SUM(cr.cr_return_amount), 0), 2) AS loss_to_return_ratio,
    MIN(dr.d_date) AS earliest_return_date,
    MAX(dr.d_date) AS latest_return_date,
    MIN(dcs.d_date) AS first_sales_date,
    MIN(dct.d_date) AS first_shipto_date
FROM catalog_returns cr
JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN date_dim dcs ON c_ret.c_first_sales_date_sk = dcs.d_date_sk
JOIN date_dim dct ON c_ret.c_first_shipto_date_sk = dct.d_date_sk
GROUP BY
    dr.d_year,
    dr.d_month_seq,
    s.s_store_id,
    s.s_city,
    s.s_state,
    c_ret.c_customer_id,
    c_ref.c_customer_id
HAVING
    SUM(cr.cr_return_amount) > 1000
ORDER BY
    dr.d_year,
    dr.d_month_seq,
    s.s_store_id

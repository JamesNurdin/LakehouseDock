SELECT
    cp.cp_department,
    cp.cp_type,
    (ds.d_year - 2000) AS year_offset,
    dsh.d_month_seq AS ship_month,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_coupon_amt) AS total_coupon,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cs.cs_net_paid_inc_tax) - SUM(cr.cr_return_amount) - SUM(cr.cr_net_loss) AS net_revenue,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
   AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim ds
    ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN date_dim dsh
    ON cs.cs_ship_date_sk = dsh.d_date_sk
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN date_dim dstart
    ON cp.cp_start_date_sk = dstart.d_date_sk
JOIN date_dim dend
    ON cp.cp_end_date_sk = dend.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
GROUP BY
    cp.cp_department,
    cp.cp_type,
    (ds.d_year - 2000),
    dsh.d_month_seq,
    s.s_state
HAVING COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY total_net_paid DESC
LIMIT 100

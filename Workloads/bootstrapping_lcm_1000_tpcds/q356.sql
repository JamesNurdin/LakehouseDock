SELECT
    dr.d_year AS return_year,
    ds.d_year AS sold_year,
    w.w_state AS warehouse_state,
    MIN(dsh.d_month_seq) AS ship_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS total_return_orders,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales_ext_price,
    AVG(cs.cs_quantity) AS avg_sales_quantity,
    SUM(CASE WHEN cr.cr_return_tax > 10 THEN cr.cr_return_tax ELSE 0 END) AS high_tax_return_total,
    COUNT(*) FILTER (WHERE cs.cs_coupon_amt > 0) AS orders_with_coupon,
    COUNT(DISTINCT s.s_city) AS distinct_closed_store_cities
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN date_dim ds
    ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN date_dim dsh
    ON cs.cs_ship_date_sk = dsh.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
    AND cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
GROUP BY
    dr.d_year,
    ds.d_year,
    w.w_state
HAVING
    SUM(cr.cr_net_loss) > 0
ORDER BY
    total_return_net_loss DESC
LIMIT 100

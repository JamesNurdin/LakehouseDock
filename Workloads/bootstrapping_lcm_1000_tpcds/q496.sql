SELECT
    s.s_store_id,
    s.s_store_name,
    sm.sm_type,
    d_sold.d_year AS sales_year,
    d_sold.d_month_seq AS sales_month_seq,
    d_return.d_year AS return_year,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    SUM(cr.cr_net_loss) AS total_returns_net_loss,
    SUM(cs.cs_net_paid) - SUM(cr.cr_net_loss) AS net_revenue,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    AVG(cs.cs_coupon_amt) AS avg_coupon_amount,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_quantity) AS total_quantity_returned,
    CASE
        WHEN SUM(cs.cs_quantity) > 0 THEN SUM(cr.cr_return_quantity) * 100.0 / SUM(cs.cs_quantity)
        ELSE 0
    END AS return_rate_percent,
    SUM(cs.cs_ext_ship_cost) AS total_shipping_cost,
    SUM(cr.cr_return_ship_cost) AS total_return_shipping_cost,
    SUM(cs.cs_ext_tax) AS total_sales_tax,
    SUM(cr.cr_return_tax) AS total_return_tax
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    sm.sm_type,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_return.d_year
ORDER BY net_revenue DESC
LIMIT 100

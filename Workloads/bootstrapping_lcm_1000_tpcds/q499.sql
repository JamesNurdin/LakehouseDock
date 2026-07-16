SELECT
    s.s_store_id,
    s.s_store_name,
    ds.d_year AS sold_year,
    ds.d_moy AS sold_month,
    bhd.hd_buy_potential AS buyer_buy_potential,
    shd.hd_buy_potential AS shipper_buy_potential,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(cr.cr_reversed_charge) AS total_reversed_charge,
    SUM(cr.cr_fee) AS total_fee,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_returns,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_quantity) AS total_quantity_returned,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    SUM(CASE WHEN cs.cs_coupon_amt > 0 THEN cs.cs_coupon_amt ELSE 0 END) AS total_coupon_amount,
    MAX(dsh.d_date) AS latest_ship_date,
    MIN(dr.d_date) AS earliest_return_date,
    COUNT(*) AS row_count
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
JOIN date_dim ds
    ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN date_dim dsh
    ON cs.cs_ship_date_sk = dsh.d_date_sk
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN date_dim dcl
    ON cr.cr_returned_date_sk = dcl.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dcl.d_date_sk
JOIN household_demographics bhd
    ON cs.cs_bill_hdemo_sk = bhd.hd_demo_sk
JOIN household_demographics shd
    ON cs.cs_ship_hdemo_sk = shd.hd_demo_sk
JOIN household_demographics rfd
    ON cr.cr_refunded_hdemo_sk = rfd.hd_demo_sk
JOIN household_demographics rrt
    ON cr.cr_returning_hdemo_sk = rrt.hd_demo_sk
WHERE ds.d_year BETWEEN 2000 AND 2005
GROUP BY ROLLUP (s.s_store_id, s.s_store_name, ds.d_year, ds.d_moy, bhd.hd_buy_potential, shd.hd_buy_potential)
HAVING SUM(cs.cs_net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100

SELECT
    dr.d_year AS return_year,
    dr.d_month_seq AS return_month,
    hd_refunded.hd_buy_potential AS refunded_buy_potential,
    hd_returning.hd_vehicle_count AS returning_vehicle_count,
    hd_bill.hd_income_band_sk AS bill_income_band,
    hd_ship.hd_dep_count AS ship_dep_count,
    s.s_store_name,
    s.s_state,
    dstore.d_year AS store_closed_year,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales_net_paid_inc_tax,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS num_sales
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
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
JOIN date_dim dstore
    ON s.s_closed_date_sk = dstore.d_date_sk
WHERE dr.d_year = 2001
  AND s.s_state = 'CA'
GROUP BY
    dr.d_year,
    dr.d_month_seq,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_vehicle_count,
    hd_bill.hd_income_band_sk,
    hd_ship.hd_dep_count,
    s.s_store_name,
    s.s_state,
    dstore.d_year
ORDER BY total_return_net_loss DESC
LIMIT 100

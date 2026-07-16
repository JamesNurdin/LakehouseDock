SELECT
    s.s_store_id,
    s.s_city,
    d_return.d_year,
    d_return.d_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cs.cs_net_paid) AS avg_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_paid_inc_tax) - SUM(cr.cr_refunded_cash) AS net_sales_vs_refunds,
    MAX(d_return.d_date) AS latest_return_date
FROM catalog_returns AS cr
JOIN catalog_sales AS cs
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim AS d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim AS d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim AS d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics AS cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics AS cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_demographics AS cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics AS cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN store AS s
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_return.d_year = 2001
GROUP BY s.s_store_id, s.s_city, d_return.d_year, d_return.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100

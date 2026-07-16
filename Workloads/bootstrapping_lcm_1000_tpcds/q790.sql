SELECT
    s.s_store_id,
    s.s_city,
    d_closure.d_date AS store_closed_date,
    d_closure.d_year AS closure_year,
    d_closure.d_month_seq AS closure_month,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    SUM(cr.cr_net_loss) AS total_returns_net_loss,
    (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) AS net_profit_after_returns
FROM store s
JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_closure.d_date_sk
JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
WHERE d_closure.d_year = 2001
GROUP BY
    s.s_store_id,
    s.s_city,
    d_closure.d_date,
    d_closure.d_year,
    d_closure.d_month_seq,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY net_profit_after_returns DESC
LIMIT 100

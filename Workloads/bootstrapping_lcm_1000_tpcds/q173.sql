SELECT
    d_ret.d_date AS return_date,
    s.s_store_name,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cs.cs_net_paid) AS total_sales_amount,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    AVG(cs.cs_net_profit) AS avg_sales_profit,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2000
GROUP BY
    d_ret.d_date,
    s.s_store_name,
    s.s_state,
    d_sold.d_date,
    d_ship.d_date
ORDER BY total_catalog_net_loss DESC
LIMIT 100

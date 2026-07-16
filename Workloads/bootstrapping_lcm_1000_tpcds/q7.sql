SELECT
    s.s_store_id,
    d_return.d_year AS return_year,
    d_sold.d_year   AS sold_year,
    d_ship.d_year   AS ship_year,
    w.w_warehouse_name,
    SUM(cs.cs_net_paid)                     AS total_sales_net_paid,
    SUM(cs.cs_net_profit)                   AS total_sales_net_profit,
    SUM(cr.cr_return_amount)                AS total_return_amount,
    SUM(cr.cr_net_loss)                     AS total_return_net_loss,
    (SUM(cs.cs_net_paid) - SUM(cr.cr_return_amount)) AS net_sales_amount,
    (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss))    AS net_profit_after_returns,
    ROW_NUMBER() OVER (
        PARTITION BY s.s_store_id
        ORDER BY (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) DESC
    ) AS profit_rank_by_store
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cs.cs_item_sk = cr.cr_item_sk
   AND cs.cs_order_number = cr.cr_order_number
   AND cs.cs_warehouse_sk = cr.cr_warehouse_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
GROUP BY
    s.s_store_id,
    d_return.d_year,
    d_sold.d_year,
    d_ship.d_year,
    w.w_warehouse_name
ORDER BY net_profit_after_returns DESC
LIMIT 100

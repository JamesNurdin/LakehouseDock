SELECT
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    FLOOR((d_sold.d_month_seq - 1) / 3) + 1 AS quarter_of_year,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cs.cs_quantity) AS avg_catalog_quantity,
    AVG(ss.ss_quantity) AS avg_store_quantity,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    FLOOR((d_sold.d_month_seq - 1) / 3) + 1
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_catalog_net_paid DESC
LIMIT 100

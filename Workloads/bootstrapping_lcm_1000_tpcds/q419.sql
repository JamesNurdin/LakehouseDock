SELECT
    s.s_store_id,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    wp.wp_type,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(sr.sr_fee) AS total_return_fee,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_cnt,
    AVG(cs.cs_quantity) AS avg_quantity_sold,
    AVG(sr.sr_return_quantity) AS avg_quantity_returned,
    SUM(cs.cs_sales_price) AS total_sales_price,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    wp.wp_type
ORDER BY total_net_profit DESC
LIMIT 100

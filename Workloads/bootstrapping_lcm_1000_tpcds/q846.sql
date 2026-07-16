SELECT
    p.p_promo_name,
    p.p_cost,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    s.s_store_id,
    s.s_city,
    d_store_closed.d_date AS store_closed_date,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    SUM(cs.cs_net_paid) AS total_sales_amount,
    SUM(cs.cs_quantity) AS total_sales_quantity,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(cs.cs_net_profit) - SUM(sr.sr_net_loss) AS net_profit_after_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets
FROM catalog_sales cs
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_end.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
GROUP BY
    p.p_promo_name,
    p.p_cost,
    d_start.d_date,
    d_end.d_date,
    s.s_store_id,
    s.s_city,
    d_store_closed.d_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq
ORDER BY total_sales_amount DESC
LIMIT 100

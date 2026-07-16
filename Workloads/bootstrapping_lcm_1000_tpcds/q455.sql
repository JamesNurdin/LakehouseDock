SELECT
    p.p_promo_name,
    s.s_state,
    d_date.d_year AS sale_year,
    d_ship.d_month_seq AS ship_month_seq,
    d_p_start.d_year AS promo_start_year,
    d_p_end.d_year AS promo_end_year,
    d_store_closed.d_year AS store_closed_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS unique_orders,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS unique_returns,
    CASE
        WHEN SUM(sr.sr_net_loss) = 0 THEN NULL
        ELSE SUM(cs.cs_net_profit) / SUM(sr.sr_net_loss)
    END AS profit_to_loss_ratio,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cs.cs_ext_sales_price) - SUM(cs.cs_ext_discount_amt) AS net_sales_after_discount,
    (SUM(cs.cs_net_paid) - SUM(sr.sr_net_loss)) AS net_paid_minus_return_loss
FROM date_dim d_date
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_date.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_p_start
    ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end
    ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_date.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
GROUP BY
    p.p_promo_name,
    s.s_state,
    d_date.d_year,
    d_ship.d_month_seq,
    d_p_start.d_year,
    d_p_end.d_year,
    d_store_closed.d_year
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_net_profit DESC
LIMIT 100

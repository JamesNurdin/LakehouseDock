SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq AS month_seq,
    p.p_promo_name,
    p.p_channel_tv,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_return_loss,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(s.s_tax_percentage) AS avg_tax_percent,
    MIN(d_ship.d_date) AS first_ship_date,
    MAX(d_ship.d_date) AS last_ship_date
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
WHERE d_sold.d_year = 2001
  AND d_promo_start.d_date_sk <= d_sold.d_date_sk
  AND d_promo_end.d_date_sk >= d_sold.d_date_sk
  AND p.p_discount_active = 'Y'
  AND s.s_state = 'CA'
  AND cs.cs_quantity > 0
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    p.p_channel_tv
ORDER BY total_net_profit DESC
LIMIT 100

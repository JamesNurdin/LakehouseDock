SELECT
    p.p_promo_id,
    p.p_promo_name,
    s.s_store_id,
    s.s_store_name,
    d_promo_start.d_year AS promo_start_year,
    d_promo_end.d_year AS promo_end_year,
    d_store_closed.d_year AS store_closed_year,
    d_sold.d_year AS sale_year,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    COUNT(DISTINCT cr.cr_order_number) AS total_returns,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_net_loss,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_quantity_returned,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    CASE
        WHEN SUM(cs.cs_net_paid) = 0 THEN NULL
        ELSE (COALESCE(SUM(cr.cr_net_loss), 0) / SUM(cs.cs_net_paid)) * 100.0
    END AS loss_to_paid_pct
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND d_sold.d_year >= 1990
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    s.s_store_id,
    s.s_store_name,
    d_promo_start.d_year,
    d_promo_end.d_year,
    d_store_closed.d_year,
    d_sold.d_year
ORDER BY total_net_paid DESC

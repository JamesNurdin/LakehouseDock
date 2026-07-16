SELECT
    s.s_store_id,
    s.s_store_name,
    p.p_promo_id,
    p.p_promo_name,
    d_promo_start.d_year AS promo_start_year,
    d_promo_end.d_year   AS promo_end_year,
    SUM(cs.cs_ext_sales_price)                     AS total_sales_amount,
    SUM(cs.cs_net_profit)                          AS total_net_profit,
    SUM(cs.cs_quantity)                            AS total_quantity_sold,
    COUNT(DISTINCT cs.cs_order_number)             AS num_orders,
    COALESCE(SUM(wr.wr_return_amt), 0)             AS total_return_amount,
    COALESCE(SUM(wr.wr_net_loss), 0)               AS total_return_loss,
    COUNT(DISTINCT wr.wr_order_number)             AS num_returns,
    AVG(cs.cs_ext_discount_amt)                    AS avg_discount_amount,
    (SUM(cs.cs_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales_after_returns,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank_by_store
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
LEFT JOIN store s
    ON s.s_closed_date_sk = d_promo_end.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_promo_start.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    p.p_promo_id,
    p.p_promo_name,
    d_promo_start.d_year,
    d_promo_end.d_year
ORDER BY net_sales_after_returns DESC
LIMIT 100

SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    dclosed.d_year AS store_closed_year,
    dr.d_year    AS return_year,
    ds.d_year    AS sales_year,
    dship.d_year AS ship_year,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    dpromo_end.d_year AS promo_end_year,
    SUM(ws.ws_ext_sales_price)      AS total_sales_amount,
    SUM(ws.ws_net_profit)           AS total_net_profit,
    SUM(sr.sr_net_loss)             AS total_return_loss,
    SUM(sr.sr_return_quantity)      AS total_return_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(p.p_cost)                   AS total_promo_cost,
    (SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) - SUM(p.p_cost)) AS net_effect
FROM store s
JOIN store_returns sr
     ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dr
     ON dr.d_date_sk = sr.sr_returned_date_sk
JOIN date_dim dclosed
     ON dclosed.d_date_sk = s.s_closed_date_sk
JOIN promotion p
     ON p.p_start_date_sk = dr.d_date_sk
JOIN date_dim dpromo_end
     ON dpromo_end.d_date_sk = p.p_end_date_sk
JOIN web_sales ws
     ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim ds
     ON ds.d_date_sk = ws.ws_sold_date_sk
JOIN date_dim dship
     ON dship.d_date_sk = ws.ws_ship_date_sk
WHERE dr.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    dclosed.d_year,
    dr.d_year,
    ds.d_year,
    dship.d_year,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    dpromo_end.d_year
ORDER BY net_effect DESC
LIMIT 100

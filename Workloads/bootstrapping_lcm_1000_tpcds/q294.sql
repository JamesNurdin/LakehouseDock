SELECT
    p.p_promo_id,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cr.cr_net_loss) AS total_returns,
    SUM(cs.cs_net_paid) - SUM(cr.cr_net_loss) AS net_revenue,
    COUNT(DISTINCT s.s_store_id) AS closed_stores
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
   AND cs.cs_ship_date_sk = d.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
   AND p.p_start_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
ORDER BY net_revenue DESC
LIMIT 100

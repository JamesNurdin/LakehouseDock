SELECT
    d.d_year,
    s.s_state,
    s.s_store_name,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(sr.sr_net_loss) AS total_return_loss,
    AVG(wp.wp_image_count) FILTER (WHERE wp.wp_image_count IS NOT NULL) AS avg_images_per_page,
    SUM(CASE WHEN cs.cs_net_profit > cs.cs_net_paid THEN cs.cs_net_profit - cs.cs_net_paid ELSE 0 END) AS extra_profit
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_ship_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
    AND wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2002
  AND s.s_market_desc = 'Market 1'
GROUP BY d.d_year, s.s_state, s.s_store_name
HAVING SUM(cs.cs_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100

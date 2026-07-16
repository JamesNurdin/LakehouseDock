SELECT
    cp.cp_department,
    d_sold.d_year,
    CASE 
        WHEN p.p_channel_tv = 'Y' THEN 'TV' 
        WHEN p.p_channel_email = 'Y' THEN 'Email' 
        ELSE 'Other' 
    END AS promo_channel,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_net_profit) AS avg_profit,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT s.s_store_id) AS num_stores
FROM catalog_page cp
JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_page_end ON cp.cp_end_date_sk = d_page_end.d_date_sk
JOIN date_dim d_page_start ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_store ON cs.cs_sold_date_sk = d_store.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_store.d_date_sk
WHERE d_sold.d_year BETWEEN 1998 AND 2002
  AND cs.cs_quantity > 0
GROUP BY cp.cp_department,
         d_sold.d_year,
         CASE 
            WHEN p.p_channel_tv = 'Y' THEN 'TV' 
            WHEN p.p_channel_email = 'Y' THEN 'Email' 
            ELSE 'Other' 
         END
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100

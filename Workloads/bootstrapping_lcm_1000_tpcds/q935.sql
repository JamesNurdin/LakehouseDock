SELECT
    d_sold.d_year,
    d_sold.d_moy AS month,
    s.s_state,
    i.i_category,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_sales_price, 0)) * 100 AS avg_discount_pct,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items_sold,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    SUM(wp.wp_image_count) AS total_image_count,
    COUNT(DISTINCT s.s_store_sk) AS distinct_stores_closed,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay_days,
    SUM(CASE WHEN cs.cs_sales_price > 100 THEN cs.cs_sales_price ELSE 0 END) AS high_price_sales_sum,
    SUM(CASE WHEN cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_sales_price, 0) > 0.1 THEN cs.cs_ext_sales_price ELSE 0 END) AS discount_over_10pct_sales,
    SUM(cs.cs_net_paid) / NULLIF(SUM(cs.cs_net_profit), 0) AS net_paid_to_profit_ratio
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sold.d_year BETWEEN 1998 AND 2000
  AND s.s_state = 'CA'
  AND i.i_category = 'Electronics'
  AND wp.wp_type = 'product'
GROUP BY
    d_sold.d_year,
    d_sold.d_moy,
    s.s_state,
    i.i_category,
    wp.wp_type
ORDER BY
    d_sold.d_year,
    d_sold.d_moy

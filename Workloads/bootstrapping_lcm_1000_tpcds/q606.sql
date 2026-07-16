SELECT
    ds_sold.d_year AS sale_year,
    ds_sold.d_month_seq AS sale_month_seq,
    s.s_state,
    wp.wp_type,
    COUNT(*) AS sale_transactions,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    ROUND(SUM(cs.cs_net_paid) / NULLIF(SUM(cs.cs_quantity), 0), 2) AS avg_price_per_qty,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    SUM(CASE WHEN cs.cs_ext_discount_amt > 0 THEN 1 ELSE 0 END) AS discounted_sales_cnt,
    AVG(CASE WHEN ds_ship.d_date > ds_sold.d_date THEN date_diff('day', ds_sold.d_date, ds_ship.d_date) END) AS avg_shipping_delay_days,
    SUM(CASE WHEN wp.wp_image_count > 5 THEN cs.cs_quantity ELSE 0 END) AS qty_high_image_pages,
    AVG(date_diff('day', ds_sold.d_date, ds_access.d_date)) AS avg_days_between_sale_and_page_access,
    MIN(ds_access.d_date) AS earliest_page_access_date,
    MAX(ds_access.d_date) AS latest_page_access_date
FROM catalog_sales cs
JOIN date_dim ds_sold
    ON cs.cs_sold_date_sk = ds_sold.d_date_sk
JOIN date_dim ds_ship
    ON cs.cs_ship_date_sk = ds_ship.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = ds_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = ds_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = ds_sold.d_date_sk
JOIN date_dim ds_access
    ON wp.wp_access_date_sk = ds_access.d_date_sk
GROUP BY
    ds_sold.d_year,
    ds_sold.d_month_seq,
    s.s_state,
    wp.wp_type
HAVING
    SUM(cs.cs_net_paid) > 50000
ORDER BY total_net_paid DESC
LIMIT 100

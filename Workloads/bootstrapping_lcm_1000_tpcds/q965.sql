SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_type,
    dd_sold.d_year AS sold_year,
    dd_sold.d_month_seq AS sold_month,
    dd_ship.d_year AS ship_year,
    dd_ship.d_month_seq AS ship_month,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    CASE
        WHEN SUM(cs.cs_quantity) > 0 THEN SUM(cs.cs_net_profit) / SUM(cs.cs_quantity)
        ELSE NULL
    END AS profit_per_unit,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    wp.wp_image_count,
    wp.wp_link_count,
    (wp.wp_image_count + wp.wp_link_count) AS total_page_elements,
    dd_creation.d_date AS page_creation_date,
    dd_access.d_date AS page_access_date
FROM catalog_sales cs
JOIN date_dim dd_sold
    ON cs.cs_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
    ON cs.cs_ship_date_sk = dd_ship.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = dd_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_creation
    ON wp.wp_creation_date_sk = dd_creation.d_date_sk
JOIN date_dim dd_access
    ON wp.wp_access_date_sk = dd_access.d_date_sk
WHERE dd_sold.d_year = 2022
  AND s.s_state = 'CA'
  AND wp.wp_type IS NOT NULL
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_type,
    dd_sold.d_year,
    dd_sold.d_month_seq,
    dd_ship.d_year,
    dd_ship.d_month_seq,
    wp.wp_image_count,
    wp.wp_link_count,
    dd_creation.d_date,
    dd_access.d_date,
    (wp.wp_image_count + wp.wp_link_count)
HAVING SUM(cs.cs_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 50

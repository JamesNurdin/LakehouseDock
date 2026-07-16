SELECT
    d_sold.d_year,
    d_sold.d_quarter_seq,
    s.s_division_name,
    wp.wp_type,
    CASE 
        WHEN d_sold.d_month_seq <= 6 THEN 'H1'
        ELSE 'H2'
    END AS half_year,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_profit,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(CASE WHEN d_ship.d_weekend = 'Y' THEN ws.ws_ext_sales_price ELSE 0 END) AS weekend_sales,
    SUM(CASE WHEN d_creation.d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_pages_created,
    COUNT(DISTINCT CASE WHEN d_access.d_weekend = 'Y' THEN wp.wp_web_page_sk END) AS weekend_page_accesses
FROM date_dim d_sold
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN inventory i
    ON i.inv_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_seq,
    s.s_division_name,
    wp.wp_type,
    CASE 
        WHEN d_sold.d_month_seq <= 6 THEN 'H1'
        ELSE 'H2'
    END
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100

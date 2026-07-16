WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sold.d_year,
        d_sold.d_quarter_name,
        d_sold.d_weekend,
        CASE WHEN d_sold.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
        t.t_hour,
        t.t_meal_time,
        wp.wp_type,
        wp.wp_url,
        d_page_creation.d_date AS page_creation_date,
        d_page_access.d_date AS page_access_date,
        date_diff('day', d_page_creation.d_date, d_page_access.d_date) AS days_to_access,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_page_creation
        ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
    JOIN date_dim d_page_access
        ON wp.wp_access_date_sk = d_page_access.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2022
      AND s.s_state = 'CA'
      AND wp.wp_type = 'article'
      AND t.t_meal_time = 'Lunch'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sold.d_year,
        d_sold.d_quarter_name,
        d_sold.d_weekend,
        t.t_hour,
        t.t_meal_time,
        wp.wp_type,
        wp.wp_url,
        d_page_creation.d_date,
        d_page_access.d_date
    HAVING SUM(ws.ws_ext_sales_price) > 10000
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    d_year,
    d_quarter_name,
    day_type,
    t_hour,
    t_meal_time,
    wp_type,
    wp_url,
    page_creation_date,
    page_access_date,
    days_to_access,
    num_orders,
    total_sales,
    total_profit,
    total_discount,
    avg_discount,
    max_sales_price,
    min_sales_price,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS store_sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100

WITH sales_by_store_page AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        wp.wp_url,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
        MIN(d_sold.d_date) AS first_sold_date,
        MAX(d_ship.d_date) AS last_ship_date,
        MAX(d_creation.d_date) AS page_creation_date,
        MAX(d_access.d_date) AS page_access_date
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_sold.d_year = 2002
      AND d_ship.d_year = 2002
    GROUP BY s.s_store_id, s.s_store_name, s.s_city, wp.wp_url
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    wp_url,
    num_orders,
    total_quantity,
    total_sales_amount,
    total_net_profit,
    avg_coupon_amount,
    avg_discount_amount,
    first_sold_date,
    last_ship_date,
    page_creation_date,
    page_access_date,
    CASE
        WHEN total_net_profit > 100000 THEN 'High'
        WHEN total_net_profit > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY s_store_id ORDER BY total_net_profit DESC) AS profit_rank_within_store,
    PERCENT_RANK() OVER (ORDER BY total_net_profit) AS overall_profit_percentile
FROM sales_by_store_page
ORDER BY total_net_profit DESC
LIMIT 100

WITH sales_agg AS (
    SELECT
        d_sold.d_current_year AS current_year,
        d_sold.d_current_month AS current_month,
        d_sold.d_week_seq AS week_seq,
        s.s_store_id AS store_id,
        s.s_division_name AS division_name,
        wp.wp_type AS page_type,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        MAX(d_ship.d_date) AS latest_ship_date,
        MIN(d_creation.d_date) AS earliest_page_creation_date,
        MAX(d_access.d_date) AS latest_page_access_date
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2022
      AND s.s_state = 'CA'
      AND wp.wp_type = 'Content'
    GROUP BY
        d_sold.d_current_year,
        d_sold.d_current_month,
        d_sold.d_week_seq,
        s.s_store_id,
        s.s_division_name,
        wp.wp_type
)
SELECT
    current_year,
    current_month,
    week_seq,
    store_id,
    division_name,
    page_type,
    total_quantity_sold,
    total_sales_amount,
    total_net_profit,
    avg_coupon_amount,
    total_inventory_on_hand,
    distinct_orders,
    latest_ship_date,
    earliest_page_creation_date,
    latest_page_access_date,
    total_sales_amount / NULLIF(total_inventory_on_hand, 0) AS sales_per_inventory,
    total_net_profit / NULLIF(total_sales_amount, 0) AS profit_margin,
    RANK() OVER (PARTITION BY current_month ORDER BY total_net_profit DESC) AS profit_rank_month
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100

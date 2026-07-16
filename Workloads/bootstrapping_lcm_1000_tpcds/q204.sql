WITH aggregated AS (
    SELECT
        d_sold.d_year,
        d_sold.d_month_seq,
        i.i_category,
        i.i_brand,
        s.s_state,
        s.s_market_desc,
        wp.wp_type,
        d_wp_creation.d_year AS page_creation_year,
        d_wp_access.d_year AS page_access_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        date_diff('day', d_sold.d_date, d_ship.d_date) AS days_to_ship
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        i.i_category,
        i.i_brand,
        s.s_state,
        s.s_market_desc,
        wp.wp_type,
        d_wp_creation.d_year,
        d_wp_access.d_year,
        d_sold.d_date,
        d_ship.d_date
    HAVING SUM(ws.ws_ext_sales_price) > 10000
)
SELECT
    agg.d_year,
    agg.d_month_seq,
    agg.i_category,
    agg.i_brand,
    agg.s_state,
    agg.s_market_desc,
    agg.wp_type,
    agg.page_creation_year,
    agg.page_access_year,
    agg.total_sales,
    agg.total_discount,
    agg.avg_profit,
    agg.distinct_orders,
    agg.days_to_ship,
    CASE
        WHEN agg.days_to_ship = 0 THEN 'Same Day'
        WHEN agg.days_to_ship <= 7 THEN 'Within Week'
        ELSE 'Delayed'
    END AS ship_speed_category,
    ROW_NUMBER() OVER (PARTITION BY agg.s_market_desc ORDER BY agg.total_sales DESC) AS market_sales_rank,
    PERCENT_RANK() OVER (PARTITION BY agg.wp_type ORDER BY agg.total_sales DESC) AS sales_percentile_by_page_type,
    COUNT(*) OVER (PARTITION BY agg.i_category) AS rows_per_category
FROM aggregated agg
ORDER BY agg.total_sales DESC
LIMIT 100

WITH joined_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        wp.wp_web_page_id,
        wp.wp_max_ad_count,
        wp.wp_image_count,
        ca.ca_state,
        ca.ca_country,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        td.t_hour,
        td.t_am_pm,
        td.t_sub_shift
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_am_pm = 'PM'
      AND wp.wp_max_ad_count >= 2
      AND ca.ca_state = 'CA'
      AND hd.hd_buy_potential = '501-1000'
      AND td.t_hour BETWEEN 12 AND 17
),
filtered_pages AS (
    SELECT wp_web_page_id FROM web_page WHERE wp_image_count > 5
    UNION
    SELECT wp_web_page_id FROM web_page WHERE wp_max_ad_count = 0
),
agg_sales AS (
    SELECT
        ca_state,
        wp_web_page_id,
        CASE
            WHEN ws_net_profit > 1000 THEN 'High'
            WHEN ws_net_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS num_orders
    FROM joined_sales
    WHERE wp_web_page_id IN (SELECT wp_web_page_id FROM filtered_pages)
    GROUP BY
        ca_state,
        wp_web_page_id,
        CASE
            WHEN ws_net_profit > 1000 THEN 'High'
            WHEN ws_net_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END
    HAVING SUM(ws_ext_sales_price) > 10000
)
SELECT
    DISTINCT ca_state,
    wp_web_page_id,
    profit_category,
    total_sales,
    num_orders,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS state_sales_rank,
    CASE WHEN total_profit > 5000 THEN 'Very High' ELSE 'Normal' END AS profit_flag
FROM agg_sales
ORDER BY total_sales DESC, ca_state
LIMIT 100

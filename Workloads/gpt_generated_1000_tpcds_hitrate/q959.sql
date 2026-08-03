WITH intersect_orders AS (
    SELECT ws_order_number FROM web_sales WHERE ws_quantity > 5
    INTERSECT
    SELECT ws_order_number FROM web_sales WHERE ws_sales_price > 100
),
base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_date_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        wp.wp_type,
        wp.wp_url,
        d_sold.d_year,
        d_sold.d_month_seq,
        t_sold.t_hour,
        ARRAY[ws.ws_quantity, CAST(ws.ws_net_profit AS double)] AS metrics
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d_site_open
        ON wsite.web_open_date_sk = d_site_open.d_date_sk
    JOIN date_dim d_site_close
        ON wsite.web_close_date_sk = d_site_close.d_date_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_cc_close
        ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
    WHERE ws.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
      AND ws.ws_order_number NOT IN (
          SELECT ws_order_number FROM web_sales WHERE ws_net_profit < 0 AND ws_order_number < 5000
      )
)
SELECT
    b.d_year,
    b.d_month_seq,
    b.t_hour,
    COUNT(DISTINCT b.ws_item_sk) AS distinct_items,
    COUNT(DISTINCT b.wp_url) AS distinct_urls,
    SUM(b.ws_sales_price) AS total_sales,
    CASE
        WHEN SUM(b.ws_net_profit) > 0 THEN 'Overall Profitable'
        ELSE 'Overall Loss'
    END AS profit_status,
    AVG(m.metric_value) AS avg_metric_value
FROM base b
CROSS JOIN UNNEST(b.metrics) AS m(metric_value)
GROUP BY b.d_year, b.d_month_seq, b.t_hour
HAVING COUNT(DISTINCT b.ws_item_sk) > 10
ORDER BY total_sales DESC
LIMIT 100

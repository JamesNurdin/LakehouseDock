WITH base AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_order_number AS ws_order_number,
        wr.wr_return_amt AS wr_return_amt,
        wr.wr_net_loss AS wr_net_loss,
        wr.wr_order_number AS wr_order_number,
        td.t_hour,
        td.t_sub_shift,
        wp.wp_url,
        c.c_preferred_cust_flag
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer rc ON wr.wr_refunded_customer_sk = rc.c_customer_sk
    WHERE td.t_hour = 13
      AND td.t_sub_shift = 'morning'
      AND wp.wp_url = 'http://www.foo.com'
      AND c.c_preferred_cust_flag = 'Y'
      AND ws.ws_ship_date_sk BETWEEN 2451458 AND 2451500
      AND ws.ws_quantity >= 2
),
sales_agg AS (
    SELECT
        t_hour,
        wp_url,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS num_orders
    FROM base
    GROUP BY t_hour, wp_url
),
returns_agg AS (
    SELECT
        t_hour,
        wp_url,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT wr_order_number) AS num_returns
    FROM base
    GROUP BY t_hour, wp_url
),
common_keys AS (
    SELECT t_hour, wp_url FROM sales_agg
    INTERSECT
    SELECT t_hour, wp_url FROM returns_agg
)
SELECT
    ck.t_hour,
    ck.wp_url,
    sa.total_sales,
    sa.total_profit,
    ra.total_return_amt,
    ra.total_return_loss,
    sa.num_orders,
    ra.num_returns
FROM common_keys ck
JOIN sales_agg sa ON ck.t_hour = sa.t_hour AND ck.wp_url = sa.wp_url
JOIN returns_agg ra ON ck.t_hour = ra.t_hour AND ck.wp_url = ra.wp_url
ORDER BY ck.t_hour DESC, ck.wp_url
LIMIT 100

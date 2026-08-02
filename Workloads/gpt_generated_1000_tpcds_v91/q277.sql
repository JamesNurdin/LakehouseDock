WITH order_items AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_addr_sk,
        ws.ws_web_site_sk,
        ws.ws_net_paid,
        ws.ws_quantity,
        array_agg(ws.ws_item_sk) AS items_array
    FROM web_sales ws
    WHERE ws.ws_quantity > 0                -- predicate 1
    GROUP BY ws.ws_order_number,
             ws.ws_sold_date_sk,
             ws.ws_sold_time_sk,
             ws.ws_bill_addr_sk,
             ws.ws_web_site_sk,
             ws.ws_net_paid,
             ws.ws_quantity
),
order_items_unnested AS (
    SELECT
        oi.ws_order_number,
        oi.ws_sold_date_sk,
        oi.ws_sold_time_sk,
        oi.ws_bill_addr_sk,
        oi.ws_web_site_sk,
        oi.ws_net_paid,
        oi.ws_quantity,
        u.item_sk,
        u.item_position
    FROM order_items oi
    CROSS JOIN UNNEST(oi.items_array) WITH ORDINALITY AS u(item_sk, item_position)
),
joined_data AS (
    SELECT
        oi.ws_order_number,
        oi.ws_net_paid,
        d.d_date,
        d.d_year,
        t.t_hour,
        ca.ca_state,
        wsite.web_country,
        cc.cc_employees,
        s.s_state,
        s.s_store_name
    FROM order_items_unnested oi
    INNER JOIN date_dim d ON oi.ws_sold_date_sk = d.d_date_sk
    INNER JOIN time_dim t ON oi.ws_sold_time_sk = t.t_time_sk
    INNER JOIN customer_address ca ON oi.ws_bill_addr_sk = ca.ca_address_sk
    INNER JOIN web_site wsite ON oi.ws_web_site_sk = wsite.web_site_sk
    INNER JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    INNER JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    INNER JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 1999                         -- predicate 2
      AND t.t_hour BETWEEN 9 AND 17              -- predicate 3
      AND ca.ca_state = 'CA'                     -- predicate 4
      AND wsite.web_country = 'United States'    -- predicate 5
      AND cc.cc_employees > 100                  -- predicate 6
      AND s.s_state = 'WA'                       -- predicate 7
),
sales_per_store_day AS (
    SELECT
        s_store_name,
        d_date,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        AVG(ws_net_paid) AS avg_net_paid_per_order
    FROM joined_data
    GROUP BY s_store_name, d_date
),
avg_sales_per_store AS (
    SELECT
        s_store_name,
        AVG(total_net_paid) AS avg_daily_net_paid,
        SUM(num_orders) AS total_orders
    FROM sales_per_store_day
    GROUP BY s_store_name
    HAVING AVG(total_net_paid) > 1000
),
order_set_a AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
),
order_set_b AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
),
order_diff AS (
    SELECT ws_order_number FROM order_set_a
    EXCEPT
    SELECT ws_order_number FROM order_set_b
)
SELECT
    a.s_store_name,
    a.avg_daily_net_paid,
    a.total_orders,
    (SELECT COUNT(*) FROM order_diff) AS diff_orders_count
FROM avg_sales_per_store a
ORDER BY a.avg_daily_net_paid DESC
LIMIT 100

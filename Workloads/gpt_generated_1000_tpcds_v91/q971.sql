WITH
store_sales_sample AS (
    SELECT
        ss_store_sk,
        ss_addr_sk,
        ss_ext_sales_price,
        ss_net_profit,
        ss_quantity,
        ss_ticket_number
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
store_sales_joined AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_addr_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ticket_number,
        ca.ca_city,
        ca.ca_state,
        st.s_store_name AS store_name
    FROM store_sales_sample ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
),
web_sales_joined AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_web_page_sk,
        ws.ws_ship_mode_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        wp.wp_max_ad_count,
        wp.wp_type,
        sm.sm_type,
        ca_bill.ca_city AS bill_city,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_city AS ship_city,
        ca_ship.ca_state AS ship_state
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
),
web_sales_filtered AS (
    SELECT
        ws_order_number,
        ws_ext_sales_price,
        ws_net_profit,
        ws_quantity,
        ws_web_page_sk,
        ws_ship_mode_sk,
        ws_bill_addr_sk,
        ws_ship_addr_sk,
        wp_max_ad_count,
        wp_type,
        sm_type,
        bill_city,
        bill_state,
        ship_city,
        ship_state
    FROM web_sales_joined wj
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = wj.ws_order_number
    )
),
web_returns_joined AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wp.wp_type AS return_page_type,
        ca_ref.ca_city AS refunded_city,
        ca_ret.ca_city AS returning_city,
        ws.ws_ext_sales_price AS original_sales_price,
        ws.ws_net_profit AS original_net_profit
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca_ref
        ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
        ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
),
orders_without_returns AS (
    SELECT ws_order_number
    FROM web_sales
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
),
union_sales AS (
    SELECT
        store_name,
        NULL AS ship_mode,
        ss_ext_sales_price AS sales_amount,
        ss_net_profit AS net_profit,
        ss_quantity AS quantity,
        ss_ticket_number AS order_number
    FROM store_sales_joined

    UNION

    SELECT
        NULL AS store_name,
        sm_type AS ship_mode,
        ws_ext_sales_price AS sales_amount,
        ws_net_profit AS net_profit,
        ws_quantity AS quantity,
        ws_order_number AS order_number
    FROM web_sales_filtered
),
aggregated_sales AS (
    SELECT
        store_name,
        ship_mode,
        COUNT(DISTINCT order_number) AS orders,
        SUM(sales_amount) AS total_sales,
        SUM(net_profit) AS total_profit,
        AVG(sales_amount) AS avg_sale
    FROM union_sales
    GROUP BY store_name, ship_mode
)
SELECT
    store_name,
    ship_mode,
    orders,
    total_sales,
    total_profit,
    avg_sale,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS sales_rank,
    (SELECT COUNT(*) FROM store) AS total_stores,
    (SELECT COUNT(*) FROM orders_without_returns) AS orders_without_returns_cnt
FROM aggregated_sales
ORDER BY total_profit DESC
LIMIT 100

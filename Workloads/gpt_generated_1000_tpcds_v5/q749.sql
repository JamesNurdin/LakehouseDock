WITH base AS (
    SELECT
        s.s_store_name AS store_name,
        ca.ca_state AS state,
        ca.ca_location_type AS location_type,
        r.r_reason_desc AS reason_desc,
        r.r_reason_id AS reason_id,
        td.t_hour AS hour,
        td.t_am_pm AS am_pm,
        td.t_sub_shift AS sub_shift,
        ws.ws_order_number AS order_number,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_net_loss AS net_loss,
        wp.wp_type AS page_type,
        wp.wp_url AS page_url,
        s.s_gmt_offset AS gmt_offset
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_time_sk = td.t_time_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
filtered AS (
    SELECT *
    FROM base
    WHERE
        am_pm = 'PM'
        AND sub_shift = 'evening'
        AND state = 'CA'
        AND location_type = 'condo'
        AND reason_id = 'AAAAAAAAIAAAAAAA'
        AND gmt_offset > 0
        AND quantity > 1
),
agg AS (
    SELECT
        store_name,
        state,
        location_type,
        reason_desc,
        hour,
        am_pm,
        sub_shift,
        COUNT(DISTINCT order_number) AS orders,
        SUM(quantity) AS total_quantity,
        SUM(net_paid) AS total_sales,
        SUM(COALESCE(return_quantity, 0)) AS total_returns,
        SUM(COALESCE(net_loss, 0)) AS total_return_loss
    FROM filtered
    GROUP BY
        store_name,
        state,
        location_type,
        reason_desc,
        hour,
        am_pm,
        sub_shift
)
SELECT
    store_name,
    state,
    location_type,
    reason_desc,
    hour,
    am_pm,
    sub_shift,
    orders,
    total_quantity,
    total_sales,
    total_returns,
    total_return_loss,
    AVG(total_sales) OVER (PARTITION BY state) AS avg_sales_by_state
FROM agg
ORDER BY total_sales DESC
LIMIT 100

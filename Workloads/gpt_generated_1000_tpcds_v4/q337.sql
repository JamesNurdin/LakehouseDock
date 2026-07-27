WITH store_agg AS (
    SELECT
        'store' AS channel,
        ca.ca_state,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450820
    GROUP BY ca.ca_state
),
web_agg AS (
    SELECT
        'web' AS channel,
        ca.ca_state,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450820
    GROUP BY ca.ca_state
)
SELECT
    channel,
    ca_state,
    total_sales
FROM (
    SELECT channel, ca_state, total_sales FROM store_agg
    UNION ALL
    SELECT channel, ca_state, total_sales FROM web_agg
) combined
ORDER BY total_sales DESC

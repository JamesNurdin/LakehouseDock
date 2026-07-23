WITH store_sales_agg AS (
    SELECT
        ca.ca_state AS state,
        'store' AS sales_channel,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state IN ('CA', 'TX')
      AND ca.ca_gmt_offset IN (-8.00, -6.00)
    GROUP BY ca.ca_state
),
web_sales_agg AS (
    SELECT
        ca.ca_state AS state,
        'web' AS sales_channel,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state IN ('CA', 'TX')
      AND ca.ca_gmt_offset IN (-8.00, -6.00)
    GROUP BY ca.ca_state
),
catalog_sales_agg AS (
    SELECT
        ca.ca_state AS state,
        'catalog' AS sales_channel,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_class = 'medium'
      AND ca.ca_gmt_offset IN (-8.00, -6.00)
    GROUP BY ca.ca_state
)
SELECT
    state,
    sales_channel,
    total_quantity,
    total_net_paid
FROM (
    SELECT state, sales_channel, total_quantity, total_net_paid FROM store_sales_agg
    UNION ALL
    SELECT state, sales_channel, total_quantity, total_net_paid FROM web_sales_agg
    UNION ALL
    SELECT state, sales_channel, total_quantity, total_net_paid FROM catalog_sales_agg
) AS combined_sales
ORDER BY total_net_paid DESC, state ASC, sales_channel ASC
LIMIT 100

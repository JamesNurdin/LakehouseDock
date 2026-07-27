WITH store_agg AS (
    SELECT
        ca.ca_state,
        ca.ca_location_type,
        SUM(ss.ss_net_paid_inc_tax) AS store_total,
        COUNT(*) AS store_cnt
    FROM tpcds.store_sales ss
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_net_paid_inc_tax > 1000
      AND ca.ca_suite_number IN ('Suite 100', 'Suite B')
      AND ca.ca_street_type = 'Avenue'
    GROUP BY ca.ca_state, ca.ca_location_type
),
web_agg AS (
    SELECT
        ca.ca_state,
        ca.ca_location_type,
        SUM(ws.ws_net_paid_inc_ship) AS web_total,
        COUNT(*) AS web_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_net_paid_inc_ship > 1500
      AND ws.ws_sold_time_sk BETWEEN 60000 AND 80000
    GROUP BY ca.ca_state, ca.ca_location_type
)
SELECT
    sa.ca_state,
    sa.ca_location_type,
    sa.store_total,
    wa.web_total,
    (sa.store_total + wa.web_total) AS combined_total,
    CASE WHEN (sa.store_total + wa.web_total) > 5000 THEN 'High' ELSE 'Low' END AS sales_category
FROM store_agg sa
JOIN web_agg wa
    ON sa.ca_state = wa.ca_state
   AND sa.ca_location_type = wa.ca_location_type
WHERE EXISTS (
    SELECT 1
    FROM tpcds.web_sales w2
    JOIN tpcds.customer_address ca2
        ON w2.ws_bill_addr_sk = ca2.ca_address_sk
    WHERE ca2.ca_state = sa.ca_state
      AND w2.ws_net_paid_inc_ship > 2000
      AND w2.ws_sold_time_sk = 67593
)
ORDER BY combined_total DESC
LIMIT 100

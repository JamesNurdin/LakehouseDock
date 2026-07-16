WITH catalog AS (
    SELECT
        ca.ca_state AS bill_state,
        (cs.cs_net_paid + cs.cs_net_paid_inc_tax) AS net_paid_total
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
),
web AS (
    SELECT
        ca.ca_state AS bill_state,
        (ws.ws_net_paid + ws.ws_net_paid_inc_tax) AS net_paid_total
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
combined AS (
    SELECT bill_state, net_paid_total FROM catalog
    UNION ALL
    SELECT bill_state, net_paid_total FROM web
),
state_agg AS (
    SELECT
        bill_state,
        SUM(net_paid_total) AS total_net_paid
    FROM combined
    GROUP BY bill_state
)
SELECT
    RANK() OVER (ORDER BY total_net_paid DESC) AS state_rank,
    bill_state,
    total_net_paid,
    CASE
        WHEN total_net_paid >= 200000 THEN 'High'
        WHEN total_net_paid >= 100000 THEN 'Medium'
        ELSE 'Low'
    END AS payment_category
FROM state_agg
ORDER BY state_rank
LIMIT 10

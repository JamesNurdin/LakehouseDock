WITH combined AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_net_paid_inc_tax AS net_paid
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_net_paid_inc_tax > 200
    UNION ALL
    SELECT
        ca.ca_state,
        ca.ca_city,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_net_paid_inc_tax AS net_paid
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_char_count BETWEEN 5000 AND 20000
),
agg AS (
    SELECT
        ca_state,
        ca_city,
        COUNT(*) AS txn_cnt,
        SUM(net_paid) AS total_net_paid,
        AVG(discount_amt) AS avg_discount
    FROM combined
    GROUP BY ca_state, ca_city
)
SELECT
    ca_state,
    ca_city,
    txn_cnt,
    total_net_paid,
    avg_discount,
    CUME_DIST() OVER (ORDER BY total_net_paid DESC) AS net_paid_cume_dist,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY avg_discount ASC) AS discount_rank_within_state
FROM agg
WHERE txn_cnt >= 3
ORDER BY total_net_paid DESC
LIMIT 30

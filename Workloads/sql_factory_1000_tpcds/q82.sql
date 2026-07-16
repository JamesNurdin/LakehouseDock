WITH combined AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        cs.cs_ext_discount_amt AS discount_amt
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_net_paid > 1000
    UNION ALL
    SELECT
        ca.ca_state,
        ca.ca_city,
        ws.ws_ext_discount_amt AS discount_amt
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_net_paid_inc_ship_tax < 500
),
agg AS (
    SELECT
        ca_state,
        ca_city,
        COUNT(*) AS cnt,
        MAX(discount_amt) AS max_discount
    FROM combined
    GROUP BY ca_state, ca_city
)
SELECT
    ca_state,
    ca_city,
    cnt,
    max_discount,
    RANK() OVER (ORDER BY max_discount DESC) AS discount_rank,
    SUM(cnt) OVER (PARTITION BY ca_state) AS total_cnt_state
FROM agg
WHERE cnt >= 2
ORDER BY discount_rank
LIMIT 20

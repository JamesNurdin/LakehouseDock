WITH combined AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        cs.cs_ext_discount_amt AS discount_amt
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    UNION ALL
    SELECT
        ca.ca_state,
        ca.ca_city,
        ws.ws_ext_discount_amt AS discount_amt
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
agg AS (
    SELECT
        ca_state,
        ca_city,
        AVG(discount_amt) AS avg_discount
    FROM combined
    GROUP BY ca_state, ca_city
)
SELECT
    ca_state,
    ca_city,
    avg_discount,
    DENSE_RANK() OVER (ORDER BY avg_discount DESC) AS discount_rank,
    SUM(avg_discount) OVER (PARTITION BY ca_state ORDER BY avg_discount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_avg_discount_state
FROM agg
ORDER BY discount_rank
LIMIT 20

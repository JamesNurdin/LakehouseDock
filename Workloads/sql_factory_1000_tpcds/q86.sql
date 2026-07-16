WITH combined AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_quantity AS qty
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_quantity > 5
    UNION ALL
    SELECT
        ca.ca_state,
        ca.ca_city,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_quantity AS qty
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'article'
),
agg AS (
    SELECT
        ca_state,
        ca_city,
        AVG(discount_amt) AS avg_discount,
        SUM(qty) AS total_qty
    FROM combined
    GROUP BY ca_state, ca_city
)
SELECT
    ca_state,
    ca_city,
    avg_discount,
    total_qty,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY avg_discount DESC) AS state_rank,
    SUM(total_qty) OVER (ORDER BY avg_discount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_qty
FROM agg
ORDER BY avg_discount DESC
LIMIT 15

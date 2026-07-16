WITH combined AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_quantity AS qty,
        cs.cs_sold_time_sk AS time_sk
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    UNION ALL
    SELECT
        ca.ca_state,
        ca.ca_city,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_quantity AS qty,
        ws.ws_sold_time_sk AS time_sk
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_link_count < 10
),
agg AS (
    SELECT
        ca_state,
        ca_city,
        SUM(qty) AS total_qty,
        AVG(discount_amt) AS avg_discount,
        MAX(time_sk) AS latest_time_sk
    FROM combined
    GROUP BY ca_state, ca_city
)
SELECT
    ca_state,
    ca_city,
    total_qty,
    avg_discount,
    latest_time_sk,
    PERCENT_RANK() OVER (ORDER BY total_qty DESC) AS qty_percentile,
    SUM(total_qty) OVER (PARTITION BY ca_state ORDER BY avg_discount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_qty_by_state
FROM agg
ORDER BY qty_percentile DESC
LIMIT 20

WITH returns_agg AS (
    SELECT
        'Return' AS source,
        ca.ca_city AS city,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > 100.00
      AND cr.cr_return_quantity >= 10
    GROUP BY ca.ca_city
),
sales_agg AS (
    SELECT
        'Sale' AS source,
        ca.ca_city AS city,
        SUM(ws.ws_net_paid) AS total_amount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_ext_ship_cost > 200.00
      AND ws.ws_quantity >= 2
    GROUP BY ca.ca_city
),
combined AS (
    SELECT * FROM returns_agg
    UNION ALL
    SELECT * FROM sales_agg
)
SELECT
    source,
    city,
    total_amount,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_amount DESC) AS city_rank
FROM combined
ORDER BY source, city_rank
LIMIT 100

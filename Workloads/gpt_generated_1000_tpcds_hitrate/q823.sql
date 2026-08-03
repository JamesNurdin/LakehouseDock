WITH catalog_agg AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        SUM(DISTINCT cs.cs_sales_price) AS distinct_sales_amount,
        SUM(cs.cs_net_paid) AS total_paid,
        CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE c.c_customer_sk IN (
        SELECT c2.c_customer_sk FROM customer c2 WHERE c2.c_birth_year < 1970
    )
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, ca.ca_state
),
web_agg AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
        SUM(DISTINCT ws.ws_sales_price) AS distinct_sales_amount,
        SUM(ws.ws_net_paid) AS total_paid,
        CASE WHEN SUM(ws.ws_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE EXISTS (
        SELECT 1 FROM customer c2 WHERE c2.c_customer_sk = ws.ws_bill_customer_sk AND c2.c_birth_year < 1970
    )
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, ca.ca_state
)
SELECT
    year,
    state,
    distinct_items,
    distinct_sales_amount,
    total_paid,
    sales_category,
    ROW_NUMBER() OVER (ORDER BY total_paid DESC) AS rn
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) combined
ORDER BY total_paid DESC
LIMIT 100

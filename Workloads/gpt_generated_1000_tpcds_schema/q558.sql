WITH cs_sample AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_call_center_sk
    FROM catalog_sales AS cs
    TABLESAMPLE BERNOULLI (10)
    WHERE cs.cs_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2000
    )
),
ws_sample AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_net_paid,
        ws.ws_web_site_sk
    FROM web_sales AS ws
    TABLESAMPLE BERNOULLI (10)
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2000
    )
),
only_catalog AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    EXCEPT
    SELECT ws.ws_order_number
    FROM web_sales ws
)
SELECT
    COALESCE(cs.cs_order_number, ws.ws_order_number) AS order_number,
    cs.cs_net_paid,
    ws.ws_net_paid,
    CASE
        WHEN cs.cs_order_number IS NOT NULL AND ws.ws_order_number IS NULL THEN 'Catalog Only'
        WHEN ws.ws_order_number IS NOT NULL AND cs.cs_order_number IS NULL THEN 'Web Only'
        ELSE 'Both'
    END AS sales_source,
    CASE
        WHEN oc.order_number IS NOT NULL THEN 1
        ELSE 0
    END AS is_exclusive_catalog
FROM cs_sample cs
FULL OUTER JOIN ws_sample ws
    ON cs.cs_order_number = ws.ws_order_number
LEFT JOIN only_catalog oc
    ON oc.order_number = COALESCE(cs.cs_order_number, ws.ws_order_number)
WHERE (cs.cs_call_center_sk IS NOT NULL OR ws.ws_web_site_sk IS NOT NULL)
LIMIT 100

WITH catalog_agg AS (
    SELECT
        'catalog' AS source,
        SUM(DISTINCT COALESCE(cs.cs_ext_sales_price, 0)) AS total_amount,
        COUNT(DISTINCT COALESCE(cs.cs_bill_customer_sk, cr.cr_refunded_customer_sk)) AS distinct_customers
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    WHERE (cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
           OR cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000)
),
web_agg AS (
    SELECT
        'web' AS source,
        SUM(DISTINCT ws.ws_ext_sales_price) AS total_amount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_city = 'Mount Olive'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
)
SELECT source,
       total_amount,
       distinct_customers
FROM (
    SELECT source, total_amount, distinct_customers FROM catalog_agg
    UNION ALL
    SELECT source, total_amount, distinct_customers FROM web_agg
) combined
ORDER BY total_amount DESC
OFFSET 0
LIMIT 100

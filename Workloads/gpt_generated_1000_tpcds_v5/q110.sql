WITH customer_sales AS (
    SELECT
        'Customer' AS source_type,
        c.c_customer_id AS id,
        SUM(cs.cs_net_paid) AS metric_value
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
    GROUP BY c.c_customer_id
),
web_page_ads AS (
    SELECT
        'WebPage' AS source_type,
        wp.wp_web_page_id AS id,
        CAST(SUM(wp.wp_max_ad_count) AS decimal(10,2)) AS metric_value
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY wp.wp_web_page_id
)
SELECT source_type, id, metric_value
FROM customer_sales
UNION ALL
SELECT source_type, id, metric_value
FROM web_page_ads
ORDER BY metric_value DESC
LIMIT 100

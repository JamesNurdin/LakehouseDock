/* goal: Identify top customers in 2001 whose email ends with .edu and first name starts with 'J', summarizing their catalog and web sales, classifying sales tier, and showing total return amount. */
WITH catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_paid) AS catalog_sales_total
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
    GROUP BY
        cs.cs_bill_customer_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid) AS web_sales_total
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    regexp_extract(c.c_email_address, '@(.*)$', 1) AS email_domain,
    COALESCE(cs_agg.catalog_sales_total, 0) AS catalog_sales_total,
    COALESCE(ws_agg.web_sales_total, 0) AS web_sales_total,
    (COALESCE(cs_agg.catalog_sales_total, 0) + COALESCE(ws_agg.web_sales_total, 0)) AS total_sales,
    CASE
        WHEN (COALESCE(cs_agg.catalog_sales_total, 0) + COALESCE(ws_agg.web_sales_total, 0)) > 100000 THEN 'High'
        WHEN (COALESCE(cs_agg.catalog_sales_total, 0) + COALESCE(ws_agg.web_sales_total, 0)) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_tier,
    (
        SELECT SUM(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
    ) AS total_return_amount
FROM
    customer c
    LEFT JOIN catalog_sales_agg cs_agg ON cs_agg.customer_sk = c.c_customer_sk
    LEFT JOIN web_sales_agg ws_agg ON ws_agg.customer_sk = c.c_customer_sk
WHERE
    regexp_like(c.c_email_address, '\\.edu$')
    AND c.c_first_name LIKE 'J%'
    AND c.c_customer_sk IN (
        SELECT cr.cr_refunded_customer_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 0
    )
ORDER BY
    total_sales DESC
LIMIT 100

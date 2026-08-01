/*
Goal: Identify customers (including those without catalog sales) whose total sales (catalog + sampled web sales) fall into spending tiers, enrich with email prefix and a sample web‑site company name, apply string filters, rank them within each tier, and limit to the top 100 results.
*/
WITH sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)   -- sample ~10% of rows
),
customer_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REGEXP_EXTRACT(c.c_email_address, '([^@]+)@') AS email_prefix,
        COALESCE(SUM(cs.cs_net_paid), 0)               AS catalog_sales_amount,
        COALESCE(SUM(ws.ws_net_paid), 0)               AS web_sales_amount,
        CASE
            WHEN COALESCE(SUM(cs.cs_net_paid), 0) + COALESCE(SUM(ws.ws_net_paid), 0) > 10000 THEN 'HIGH'
            WHEN COALESCE(SUM(cs.cs_net_paid), 0) + COALESCE(SUM(ws.ws_net_paid), 0) > 5000  THEN 'MEDIUM'
            ELSE 'LOW'
        END                                            AS sales_category,
        MIN(ws_site.web_company_name)                 AS web_company_name_sample
    FROM
        customer c
        FULL OUTER JOIN catalog_sales cs
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        LEFT JOIN sampled_ws ws
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN web_site ws_site
            ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_sales w2
        WHERE w2.ws_bill_customer_sk = c.c_customer_sk
    )
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
)
SELECT
    ca.c_customer_id,
    ca.full_name,
    ca.email_prefix,
    ca.catalog_sales_amount,
    ca.web_sales_amount,
    ca.sales_category,
    ca.web_company_name_sample,
    CASE
        WHEN REGEXP_LIKE(ca.web_company_name_sample, '^a.*') THEN 'Starts with a'
        ELSE 'Other'
    END                                            AS company_name_category,
    ROW_NUMBER() OVER (
        PARTITION BY ca.sales_category
        ORDER BY ca.catalog_sales_amount DESC
    )                                           AS sales_rank
FROM
    customer_agg ca
WHERE
    ca.web_company_name_sample IS NOT NULL
    AND ca.web_company_name_sample LIKE '%company%'
ORDER BY
    ca.sales_category,
    sales_rank
LIMIT 100

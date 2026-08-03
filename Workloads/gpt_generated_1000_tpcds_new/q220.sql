/*
Goal: Identify the highest‑revenue customers across catalog and web channels, applying string‑based filters on customer email domains and website names. The query demonstrates regexp_like, regexp_extract, LIKE pattern matching, and concatenation, combines the two sources with UNION DISTINCT, aggregates revenue, and assigns a global row number before limiting to the top 100 rows.
*/
WITH catalog_part AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_education_status,
        SUM(cs.cs_net_paid) AS revenue,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1) AS email_domain
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^.*@example\\.com$')
      AND cd.cd_gender = 'M'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_education_status,
        c.c_email_address
),
web_part AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_education_status,
        SUM(ws.ws_net_paid) AS revenue,
        CASE
            WHEN w.web_name LIKE '%Market%' THEN 'Market'
            ELSE 'Other'
        END AS website_category
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_market_manager LIKE 'J% %'
      AND REGEXP_LIKE(w.web_name, '^(.*)(Market|Shop)(.*)$')
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_education_status,
        w.web_name
)
SELECT
    u.c_customer_sk,
    u.full_name,
    u.c_first_name,
    u.c_last_name,
    u.cd_gender,
    u.cd_education_status,
    u.revenue,
    u.email_domain,
    u.website_category,
    ROW_NUMBER() OVER (ORDER BY u.revenue DESC) AS row_num
FROM (
    SELECT
        cp.c_customer_sk,
        cp.full_name,
        cp.c_first_name,
        cp.c_last_name,
        cp.cd_gender,
        cp.cd_education_status,
        cp.revenue,
        cp.email_domain,
        NULL AS website_category
    FROM catalog_part cp
    UNION DISTINCT
    SELECT
        wp.c_customer_sk,
        wp.full_name,
        wp.c_first_name,
        wp.c_last_name,
        wp.cd_gender,
        wp.cd_education_status,
        wp.revenue,
        NULL AS email_domain,
        wp.website_category
    FROM web_part wp
) u
ORDER BY row_num
LIMIT 100

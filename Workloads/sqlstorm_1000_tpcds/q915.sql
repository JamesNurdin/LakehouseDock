WITH store_sales_agg AS (
    SELECT
        s.s_store_sk,
        c.c_customer_sk,
        d.d_year,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        MAX(d.d_date) AS max_store_sale_date
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY s.s_store_sk, c.c_customer_sk, d.d_year
),
catalog_sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        c.c_customer_sk,
        d.d_year,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions,
        MAX(d.d_date) AS max_catalog_sale_date
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY cc.cc_call_center_sk, c.c_customer_sk, d.d_year
),
web_sales_agg AS (
    SELECT
        ws.ws_web_page_sk,
        c.c_customer_sk,
        d.d_year,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
        MAX(d.d_date) AS max_web_sale_date
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY ws.ws_web_page_sk, c.c_customer_sk, d.d_year
),
customer_demog AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating
    FROM customer_demographics
)
SELECT
    COALESCE(ss.s_store_sk, -1) AS store_sk,
    COALESCE(cs.cc_call_center_sk, -1) AS call_center_sk,
    COALESCE(ws.ws_web_page_sk, -1) AS web_page_sk,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    SUM(COALESCE(ss.store_net_paid, 0)) AS total_store_net_paid,
    SUM(COALESCE(cs.catalog_net_paid, 0)) AS total_catalog_net_paid,
    SUM(COALESCE(ws.web_net_paid, 0)) AS total_web_net_paid,
    (SUM(COALESCE(ss.store_net_paid, 0)) + SUM(COALESCE(cs.catalog_net_paid, 0)) + SUM(COALESCE(ws.web_net_paid, 0))) AS total_net_paid_all,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_year) AS year_rank,
    CONCAT(
        CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred_' ELSE '' END,
        COALESCE(cd.cd_gender, 'U')
    ) AS gender_flag,
    CASE
        WHEN ss.max_store_sale_date IS NULL AND cs.max_catalog_sale_date IS NULL AND ws.max_web_sale_date IS NULL THEN 'No Sales'
        WHEN GREATEST(
            COALESCE(ss.max_store_sale_date, DATE '1900-01-01'),
            COALESCE(cs.max_catalog_sale_date, DATE '1900-01-01'),
            COALESCE(ws.max_web_sale_date, DATE '1900-01-01')
        ) = (SELECT MAX(d2.d_date) FROM date_dim d2 WHERE d2.d_year = d.d_year) THEN 'Latest Sale'
        ELSE 'Historical'
    END AS sale_status,
    (SELECT MAX(d2.d_date) FROM date_dim d2 WHERE d2.d_year = d.d_year AND d2.d_date <= DATE '2024-10-01') AS latest_date_in_year,
    CASE
        WHEN (SUM(COALESCE(ss.store_net_paid, 0)) + SUM(COALESCE(cs.catalog_net_paid, 0))) = 0 THEN NULL
        ELSE SUM(COALESCE(ws.web_net_paid, 0)) / NULLIF((SUM(COALESCE(ss.store_net_paid, 0)) + SUM(COALESCE(cs.catalog_net_paid, 0))), 0)
    END AS web_to_other_ratio,
    COALESCE(cd.cd_credit_rating, 'UNKNOWN') AS credit_rating,
    CASE WHEN c.c_birth_year IS NOT NULL THEN CAST((year(DATE '2024-10-01') - c.c_birth_year) AS VARCHAR) ELSE 'UNKNOWN' END AS age_estimate
FROM store_sales_agg ss
FULL OUTER JOIN catalog_sales_agg cs
    ON ss.c_customer_sk = cs.c_customer_sk AND ss.d_year = cs.d_year
FULL OUTER JOIN web_sales_agg ws
    ON COALESCE(ss.c_customer_sk, cs.c_customer_sk) = ws.c_customer_sk
    AND COALESCE(ss.d_year, cs.d_year) = ws.d_year
LEFT JOIN customer c
    ON COALESCE(ss.c_customer_sk, cs.c_customer_sk, ws.c_customer_sk) = c.c_customer_sk
LEFT JOIN date_dim d
    ON COALESCE(ss.d_year, cs.d_year, ws.d_year) = d.d_year
LEFT JOIN customer_demog cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE c.c_customer_sk IS NOT NULL
   OR ss.s_store_sk IS NOT NULL
   OR cs.cc_call_center_sk IS NOT NULL
   OR ws.ws_web_page_sk IS NOT NULL
GROUP BY
    ss.s_store_sk,
    cs.cc_call_center_sk,
    ws.ws_web_page_sk,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    cd.cd_gender,
    cd.cd_credit_rating,
    c.c_preferred_cust_flag,
    c.c_birth_year,
    ss.max_store_sale_date,
    cs.max_catalog_sale_date,
    ws.max_web_sale_date
HAVING SUM(COALESCE(ss.store_net_paid, 0) + COALESCE(cs.catalog_net_paid, 0) + COALESCE(ws.web_net_paid, 0)) > 0
ORDER BY total_net_paid_all DESC
LIMIT 100

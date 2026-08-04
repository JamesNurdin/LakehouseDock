WITH cd_filtered AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_purchase_estimate,
        CASE WHEN cd_purchase_estimate > 5000 THEN 'High' ELSE 'Low' END AS purchase_level
    FROM customer_demographics
    WHERE regexp_like(cd_gender, '^[MF]$')
),
intersect_customers AS (
    SELECT cs_bill_customer_sk AS customer_sk FROM catalog_sales
    INTERSECT
    SELECT ws_bill_customer_sk AS customer_sk FROM web_sales
),
combined_sales AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_bill_cdemo_sk   AS demo_sk,
        'catalog'             AS source,
        cp.cp_catalog_page_id AS identifier,
        substr(cp.cp_catalog_page_id, 1, 5) AS id_prefix,
        CASE
            WHEN regexp_like(cp.cp_description, '.*sale.*') THEN 'SalePage'
            ELSE 'Regular'
        END AS category,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_catalog_page_id LIKE 'AAAA%AAA'
    GROUP BY cs.cs_bill_customer_sk, cs.cs_bill_cdemo_sk, cp.cp_catalog_page_id, cp.cp_description
    
    UNION DISTINCT
    
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_bill_cdemo_sk   AS demo_sk,
        'web'                 AS source,
        ws_site.web_name      AS identifier,
        substr(ws_site.web_name, 1, 3) AS id_prefix,
        CASE
            WHEN regexp_like(ws_site.web_name, '^A') THEN 'StartsA'
            ELSE 'Other'
        END AS category,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_sales_price > 0
    GROUP BY ws.ws_bill_customer_sk, ws.ws_bill_cdemo_sk, ws_site.web_name
)
SELECT
    COALESCE(cs.customer_sk, sr.sr_customer_sk) AS customer_sk,
    cs.source,
    cs.identifier,
    cs.category,
    cs.total_net_paid,
    cs.sales_cnt,
    sr.sr_return_quantity,
    CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag,
    cdf.purchase_level
FROM combined_sales cs
FULL OUTER JOIN store_returns sr
    ON cs.customer_sk = sr.sr_customer_sk
LEFT JOIN cd_filtered cdf
    ON cs.demo_sk = cdf.cd_demo_sk
WHERE (cs.customer_sk IN (SELECT customer_sk FROM intersect_customers)
       OR sr.sr_customer_sk IN (SELECT customer_sk FROM intersect_customers))
ORDER BY cs.total_net_paid DESC
LIMIT 100

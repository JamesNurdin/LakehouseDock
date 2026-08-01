/*
Goal: Analyze sales performance per catalog page using string pattern filters, a Bernoulli sample, and compare against pages that have no sales. The query demonstrates regexp_like, regexp_extract, LIKE, concatenation, a correlated scalar subquery, UNION DISTINCT, EXCEPT, and ordering with a limit.
*/
WITH sampled_pages AS (
    SELECT
        cp_catalog_page_sk,
        cp_catalog_page_id,
        cp_catalog_page_number,
        cp_description
    FROM catalog_page
    TABLESAMPLE BERNOULLI (10)
),
unioned AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        SUM(cs.cs_net_paid)                         AS total_net_paid,
        COUNT(*)                                    AS sales_cnt,
        (SELECT AVG(ib.ib_lower_bound)
         FROM household_demographics hd
         JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
         WHERE hd.hd_demo_sk = cs.cs_bill_hdemo_sk) AS avg_income_lower,
        CONCAT('Page-', CAST(cp.cp_catalog_page_number AS VARCHAR)) AS page_label
    FROM sampled_pages cp
    JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(cp.cp_description, '(?i)sale')
      AND cp.cp_catalog_page_id LIKE 'AAAAAAA%'
    GROUP BY
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        cs.cs_bill_hdemo_sk

    UNION DISTINCT

    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        SUM(cs.cs_net_paid)                         AS total_net_paid,
        COUNT(*)                                    AS sales_cnt,
        (SELECT AVG(ib.ib_lower_bound)
         FROM household_demographics hd
         JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
         WHERE hd.hd_demo_sk = cs.cs_bill_hdemo_sk) AS avg_income_lower,
        CONCAT('Page-', CAST(cp.cp_catalog_page_number AS VARCHAR)) AS page_label
    FROM catalog_page cp
    JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_catalog_page_number > 10
      AND regexp_extract(cp.cp_catalog_page_id, '(A{3,})', 1) IS NOT NULL
    GROUP BY
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        cs.cs_bill_hdemo_sk
)
SELECT
    cp_sk,
    cp_id,
    cp_number,
    total_net_paid,
    sales_cnt,
    avg_income_lower,
    page_label
FROM (
    SELECT
        cp_catalog_page_sk AS cp_sk,
        cp_catalog_page_id AS cp_id,
        cp_catalog_page_number AS cp_number,
        total_net_paid,
        sales_cnt,
        avg_income_lower,
        page_label
    FROM unioned
) AS u
EXCEPT
SELECT
    cp.cp_catalog_page_sk,
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    NULL,
    NULL,
    NULL,
    NULL
FROM catalog_page cp
WHERE NOT EXISTS (
    SELECT 1 FROM catalog_sales cs WHERE cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
)
ORDER BY total_net_paid DESC
LIMIT 100

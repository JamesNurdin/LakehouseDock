WITH sales_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        SUM(DISTINCT cs.cs_ext_sales_price) AS sum_distinct_sales
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_type = 'Promotion'
    GROUP BY cs.cs_call_center_sk, cs.cs_catalog_page_sk
),
returns_agg AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers,
        SUM(DISTINCT cr.cr_return_amount) AS sum_distinct_return_amount
    FROM catalog_returns cr
    JOIN call_center cc2
        ON cr.cr_call_center_sk = cc2.cc_call_center_sk
    JOIN catalog_page cp2
        ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    WHERE cc2.cc_state = 'CA'
      AND cp2.cp_type = 'Promotion'
    GROUP BY cr.cr_call_center_sk, cr.cr_catalog_page_sk
),
full_join AS (
    SELECT
        COALESCE(s.cs_call_center_sk, r.cr_call_center_sk) AS call_center_sk,
        COALESCE(s.cs_catalog_page_sk, r.cr_catalog_page_sk) AS catalog_page_sk,
        s.distinct_customers,
        s.sum_distinct_sales,
        r.distinct_refunded_customers,
        r.sum_distinct_return_amount
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.cs_call_center_sk = r.cr_call_center_sk
       AND s.cs_catalog_page_sk = r.cr_catalog_page_sk
)
SELECT
    call_center_sk,
    catalog_page_sk,
    distinct_customers,
    sum_distinct_sales,
    NULL AS distinct_refunded_customers,
    NULL AS sum_distinct_return_amount
FROM full_join
WHERE distinct_customers IS NOT NULL

UNION

SELECT
    call_center_sk,
    catalog_page_sk,
    NULL AS distinct_customers,
    NULL AS sum_distinct_sales,
    distinct_refunded_customers,
    sum_distinct_return_amount
FROM full_join
WHERE distinct_refunded_customers IS NOT NULL

ORDER BY call_center_sk, catalog_page_sk
LIMIT 100

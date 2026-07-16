WITH
    agg_store AS (
        SELECT
            ss_customer_sk,
            SUM(ss_net_paid) AS total_store_sales,
            MAX(ss_sold_date_sk) AS last_store_date
        FROM store_sales
        GROUP BY ss_customer_sk
    ),
    agg_web AS (
        SELECT
            ws_bill_customer_sk AS customer_sk,
            SUM(ws_net_paid) AS total_web_sales,
            MAX(ws_sold_date_sk) AS last_web_date
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    ),
    agg_catalog AS (
        SELECT
            cs_bill_customer_sk AS customer_sk,
            SUM(cs_net_paid) AS total_catalog_sales,
            MAX(cs_sold_date_sk) AS last_catalog_date
        FROM catalog_sales
        GROUP BY cs_bill_customer_sk
    ),
    store_web_full AS (
        SELECT
            COALESCE(a.ss_customer_sk, b.customer_sk) AS customer_sk,
            COALESCE(a.total_store_sales, 0) AS total_store_sales,
            COALESCE(b.total_web_sales, 0) AS total_web_sales,
            GREATEST(COALESCE(a.last_store_date, 0), COALESCE(b.last_web_date, 0)) AS most_recent_activity
        FROM agg_store a
        FULL OUTER JOIN agg_web b ON a.ss_customer_sk = b.customer_sk
    ),
    union_sales AS (
        SELECT ss_customer_sk AS customer_sk, total_store_sales AS total_sales, last_store_date AS last_date FROM agg_store
        UNION ALL
        SELECT customer_sk, total_web_sales, last_web_date FROM agg_web
        UNION ALL
        SELECT customer_sk, total_catalog_sales, last_catalog_date FROM agg_catalog
    ),
    total_sales_by_customer AS (
        SELECT
            customer_sk,
            SUM(total_sales) AS grand_total_sales,
            MAX(last_date) AS most_recent_date
        FROM union_sales
        GROUP BY customer_sk
    ),
    flagged_customers AS (
        SELECT
            c.c_customer_sk,
            CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
            COALESCE(ts.grand_total_sales, 0) AS total_sales,
            ts.most_recent_date,
            CASE
                WHEN COALESCE(ts.grand_total_sales, 0) > 100000 THEN 'VIP'
                WHEN COALESCE(ts.grand_total_sales, 0) > 50000 THEN 'GOLD'
                ELSE 'STANDARD'
            END AS tier,
            ROW_NUMBER() OVER (ORDER BY COALESCE(ts.grand_total_sales, 0) DESC) AS sales_rank,
            (SELECT COUNT(DISTINCT ss_store_sk)
             FROM store_sales ss
             WHERE ss.ss_customer_sk = c.c_customer_sk) AS distinct_stores,
            (SELECT COALESCE(SUM(cr.cr_return_amount), 0)
             FROM catalog_returns cr
             JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
             WHERE cr.cr_returned_date_sk = ts.most_recent_date
               AND cr.cr_refunded_customer_sk = c.c_customer_sk) AS recent_cc_ret_amount,
            swf.total_store_sales,
            swf.total_web_sales,
            swf.most_recent_activity
        FROM customer c
        LEFT JOIN total_sales_by_customer ts ON c.c_customer_sk = ts.customer_sk
        LEFT JOIN store_web_full swf ON c.c_customer_sk = swf.customer_sk
    ),
    tier_aggregates AS (
        SELECT
            tier,
            SUM(total_sales) AS tier_sales,
            COUNT(*) AS tier_customers,
            GROUPING(tier) AS is_grand_total
        FROM flagged_customers
        GROUP BY GROUPING SETS ((tier), ())
    ),
    customers_set AS (
        SELECT c.c_customer_sk AS entity_id, 'CUSTOMER' AS entity_type FROM customer c
        UNION
        SELECT cc.cc_call_center_sk, 'CALL_CENTER' FROM call_center cc
    ),
    intersect_demo AS (
        SELECT entity_id
        FROM customers_set
        INTERSECT
        SELECT fc.c_customer_sk FROM flagged_customers fc WHERE fc.tier = 'VIP'
    ),
    final_pre AS (
        SELECT
            fc.c_customer_sk,
            fc.full_name,
            fc.tier,
            fc.sales_rank,
            fc.total_sales,
            fc.distinct_stores,
            fc.recent_cc_ret_amount,
            fc.total_store_sales,
            fc.total_web_sales,
            fc.most_recent_activity,
            CAST(fc.recent_cc_ret_amount AS DOUBLE) / NULLIF(fc.total_sales, 0) AS return_to_sales_ratio,
            CASE
                WHEN fc.tier = 'VIP' THEN 'HIGH'
                WHEN fc.tier = 'GOLD' THEN 'MEDIUM'
                ELSE 'LOW'
            END AS priority,
            REPLACE(reverse(fc.full_name), ' ', '_') AS transformed_name,
            cardinality(regexp_extract_all(fc.full_name, '[aeiouAEIOU]')) AS vowel_count,
            ln.name_len AS name_length,
            SUM(fc.total_sales) OVER (ORDER BY fc.sales_rank ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
        FROM flagged_customers fc
        LEFT JOIN intersect_demo id ON fc.c_customer_sk = id.entity_id
        CROSS JOIN LATERAL (SELECT length(fc.full_name) AS name_len) AS ln
        WHERE id.entity_id IS NOT NULL
    )
SELECT
    fp.*,
    ta.tier_sales,
    ta.tier_customers,
    ta.is_grand_total
FROM final_pre fp
LEFT JOIN tier_aggregates ta ON fp.tier = ta.tier
ORDER BY fp.sales_rank
LIMIT 100

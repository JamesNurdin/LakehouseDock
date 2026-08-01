WITH
    store_sales_agg AS (
        SELECT
            s.s_store_sk,
            s.s_store_id,
            d.d_date,
            SUM(ss.ss_net_paid) AS total_sales,
            COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY s.s_store_sk, s.s_store_id, d.d_date
    ),
    store_returns_agg AS (
        SELECT
            s.s_store_sk,
            s.s_store_id,
            d.d_date,
            SUM(sr.sr_net_loss) AS total_returns,
            COUNT(DISTINCT sr.sr_customer_sk) AS distinct_return_customers
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        GROUP BY s.s_store_sk, s.s_store_id, d.d_date
    ),
    full_store_activity AS (
        SELECT
            COALESCE(sa.s_store_sk, ra.s_store_sk) AS store_sk,
            COALESCE(sa.s_store_id, ra.s_store_id) AS store_id,
            COALESCE(sa.d_date, ra.d_date) AS activity_date,
            sa.total_sales,
            ra.total_returns,
            COALESCE(sa.distinct_customers, 0) AS distinct_customers,
            COALESCE(ra.distinct_return_customers, 0) AS distinct_return_customers
        FROM store_sales_agg sa
        FULL OUTER JOIN store_returns_agg ra
            ON sa.s_store_sk = ra.s_store_sk
            AND sa.d_date = ra.d_date
    ),
    catalog_returns_agg AS (
        SELECT
            CAST(NULL AS integer) AS store_sk,
            CAST(NULL AS varchar) AS store_id,
            d.d_date AS activity_date,
            CAST(0 AS decimal(7,2)) AS total_sales,
            SUM(cr.cr_net_loss) AS total_returns,
            CAST(0 AS bigint) AS distinct_customers,
            CAST(0 AS bigint) AS distinct_return_customers
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        GROUP BY d.d_date
    ),
    union_activity AS (
        SELECT
            store_sk,
            store_id,
            activity_date,
            total_sales,
            total_returns,
            distinct_customers,
            distinct_return_customers
        FROM full_store_activity
        UNION ALL
        SELECT DISTINCT
            store_sk,
            store_id,
            activity_date,
            total_sales,
            total_returns,
            distinct_customers,
            distinct_return_customers
        FROM catalog_returns_agg
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY ua.total_sales DESC NULLS LAST) AS row_num,
    ua.store_id,
    ua.activity_date,
    ua.total_sales,
    ua.total_returns,
    ua.distinct_customers,
    ua.distinct_return_customers,
    (
        SELECT COALESCE(SUM(ss3.ss_quantity), 0)
        FROM store_sales ss3
        WHERE ss3.ss_store_sk = ua.store_sk
    ) AS total_quantity_sold,
    CASE WHEN ua.total_sales > (SELECT AVG(ss4.ss_net_paid) FROM store_sales ss4)
        THEN 'Above Avg' ELSE 'Below Avg' END AS sales_vs_avg
FROM union_activity ua
WHERE COALESCE(ua.total_sales, 0) > (SELECT AVG(ss5.ss_net_paid) FROM store_sales ss5)
ORDER BY ua.total_sales DESC NULLS LAST
LIMIT 100

WITH store_sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM
        store_sales ss
        RIGHT OUTER JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        d.d_year
)
SELECT *
FROM (
    SELECT
        'Store' AS source_type,
        ssa.s_store_sk AS id,
        ssa.s_store_name AS name,
        ssa.d_year AS year,
        ssa.total_net_paid AS amount,
        ssa.sales_category AS category,
        (
            SELECT COUNT(DISTINCT ss2.ss_item_sk)
            FROM store_sales ss2
            WHERE ss2.ss_store_sk = ssa.s_store_sk
        ) AS extra_count
    FROM store_sales_agg ssa
    WHERE ssa.total_net_paid IS NOT NULL

    UNION ALL

    SELECT
        'Promo' AS source_type,
        p.p_promo_sk AS id,
        p.p_promo_name AS name,
        d_start.d_year AS year,
        SUM(cs.cs_net_paid_inc_tax) AS amount,
        CASE WHEN SUM(cs.cs_net_paid_inc_tax) > 5000 THEN 'Strong' ELSE 'Weak' END AS category,
        CAST(NULL AS BIGINT) AS extra_count
    FROM promotion p
    FULL OUTER JOIN catalog_sales cs
        ON p.p_promo_sk = cs.cs_promo_sk
    LEFT JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    WHERE p.p_cost > 1000
    GROUP BY
        p.p_promo_sk,
        p.p_promo_name,
        d_start.d_year
) combined
ORDER BY amount DESC
OFFSET 0
LIMIT 100

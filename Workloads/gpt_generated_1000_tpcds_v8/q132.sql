/* goal: Analyze monthly net loss trends for store and catalog returns, focusing on stores with managers whose names start with a vowel and catalog returns with reasons containing the word 'defect'. The query extracts manager first names and reason keywords, applies regex and LIKE filters, computes distinct aggregates, uses a window function, a scalar subquery, and combines store and catalog results with UNION ALL. */
WITH combined AS (
    -- Store returns aggregation
    SELECT
        'store' AS source,
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_return_quantity) AS distinct_return_qty,
        COUNT(DISTINCT r.r_reason_sk) AS distinct_reason_cnt,
        CASE
            WHEN SUM(sr.sr_net_loss) > 10000 THEN 'HIGH'
            ELSE 'NORMAL'
        END AS loss_category,
        REGEXP_EXTRACT(s.s_manager, '([A-Z][a-z]+)') AS extra_info,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_net_loss) DESC) AS rn_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE REGEXP_LIKE(s.s_manager, '^[AEIOU]')
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, s.s_manager

    UNION ALL

    -- Catalog returns aggregation
    SELECT
        'catalog' AS source,
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_return_quantity) AS distinct_return_qty,
        COUNT(DISTINCT r.r_reason_sk) AS distinct_reason_cnt,
        CASE
            WHEN SUM(cr.cr_net_loss) > 15000 THEN 'HIGH'
            ELSE 'NORMAL'
        END AS loss_category,
        MIN(REGEXP_EXTRACT(r.r_reason_desc, '(\\w+)$')) AS extra_info,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_net_loss) DESC) AS rn_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)defect')
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    c.source,
    c.d_year,
    c.month_seq,
    c.total_net_loss,
    c.distinct_return_qty,
    c.distinct_reason_cnt,
    c.loss_category,
    c.extra_info,
    c.rn_year,
    CASE
        WHEN c.total_net_loss > (SELECT AVG(total_net_loss) FROM combined) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS avg_comparison
FROM combined c
WHERE EXISTS (
    SELECT 1
    FROM web_site w
    JOIN date_dim dw ON w.web_open_date_sk = dw.d_date_sk
    WHERE dw.d_year = c.d_year
      AND w.web_state LIKE 'C%'
      AND w.web_suite_number LIKE '%Suite%'
)
ORDER BY c.source, c.d_year, c.month_seq
LIMIT 100

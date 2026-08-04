WITH returns_cte AS (
    SELECT
        d.d_year,
        CONCAT('R_', CAST(d.d_year AS VARCHAR)) AS label,
        SUM(wr.wr_return_amt_inc_tax) AS metric,
        COUNT(*) AS cnt,
        (
            SELECT MAX(wr2.wr_return_amt_inc_tax)
            FROM web_returns wr2
            WHERE wr2.wr_returned_date_sk = d.d_date_sk
        ) AS max_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE wr.wr_return_amt_inc_tax > 0
      AND regexp_like(CAST(wr.wr_fee AS VARCHAR), '^\d{2}\.\d{2}$')
    GROUP BY d.d_year, d.d_date_sk
),

pages_cte AS (
    SELECT
        d.d_year,
        SUBSTRING(cp.cp_catalog_page_id, 1, 8) AS label,
        COUNT(*) AS metric,
        MAX(cp.cp_catalog_page_id) AS max_id,
        CASE
            WHEN regexp_like(cp.cp_type, 'quarterly|monthly') THEN cp.cp_type
            ELSE 'other'
        END AS type_grp
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE cp.cp_catalog_page_id LIKE 'AAAAAAA%'
      AND cp.cp_type LIKE '%ly'
    GROUP BY d.d_year, SUBSTRING(cp.cp_catalog_page_id, 1, 8),
             CASE
                 WHEN regexp_like(cp.cp_type, 'quarterly|monthly') THEN cp.cp_type
                 ELSE 'other'
             END
),

small_dim AS (
    SELECT 1 AS flag, 'X' AS grp UNION ALL SELECT 2, 'Y'
)

SELECT final.year,
       final.label,
       SUM(final.metric) AS total_metric,
       MAX(final.max_return_amt) AS max_return_amount
FROM (
    SELECT r.d_year AS year,
           r.label,
           r.metric,
           r.max_return_amt
    FROM returns_cte r
    CROSS JOIN small_dim sd
    WHERE sd.flag = (r.d_year % 2)
    UNION
    SELECT p.d_year AS year,
           p.label,
           p.metric,
           NULL AS max_return_amt
    FROM pages_cte p
    WHERE EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_id = p.max_id
          AND regexp_like(cp2.cp_catalog_page_id, '^AAAAAAA')
    )
) AS final
GROUP BY final.year, final.label
ORDER BY final.year DESC, total_metric DESC
LIMIT 100

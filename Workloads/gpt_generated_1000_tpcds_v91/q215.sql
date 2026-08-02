WITH filtered AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_rec_start_date,
        s.s_closed_date_sk,
        s.s_store_name,
        s.s_number_employees,
        s.s_floor_space,
        s.s_gmt_offset,
        s.s_tax_percentage,
        s.s_city,
        s.s_state,
        s.s_country,
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_fy_quarter_seq,
        d.d_current_year,
        d.d_last_dom
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND d.d_fy_quarter_seq IN (3, 9, 14)
        AND d.d_current_year = 'Y'
        AND d.d_last_dom BETWEEN 2415000 AND 2416000
        AND s.s_city IN ('Highland Park', 'Fairfield', 'Wildwood')
        AND s.s_market_manager = 'Thomas Pollack'
        AND s.s_state = 'CA'
        AND s.s_tax_percentage > 5.00
)
SELECT
    COALESCE(f.s_city, 'ALL') AS city,
    f.d_fy_quarter_seq AS fy_quarter,
    COUNT(*) AS closed_store_cnt,
    SUM(f.s_floor_space) AS total_floor_space,
    AVG(f.s_number_employees) AS avg_num_employees,
    MIN(f.s_gmt_offset) AS min_gmt_offset,
    MAX(f.s_tax_percentage) AS max_tax_pct,
    (
        SELECT COUNT(*)
        FROM store s3
        WHERE s3.s_city = f.s_city
          AND s3.s_rec_start_date > DATE '2000-01-01'
    ) AS future_store_cnt
FROM filtered f
GROUP BY ROLLUP (f.s_city, f.d_fy_quarter_seq)
ORDER BY city ASC, fy_quarter ASC
OFFSET 0 ROWS
LIMIT 100

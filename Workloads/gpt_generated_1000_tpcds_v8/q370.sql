WITH sampled_cc AS (
        SELECT *
        FROM call_center
        TABLESAMPLE BERNOULLI (10)      -- sample 10% of rows
        WHERE cc_country = 'United States'
          AND cc_employees > 500
          AND cc_gmt_offset BETWEEN -5 AND 0
    ),
    set1 AS (
        SELECT cc_call_center_sk
        FROM sampled_cc
        WHERE cc_sq_ft > 1000000
    ),
    set2 AS (
        SELECT cc_call_center_sk
        FROM call_center
        WHERE cc_mkt_id IS NOT NULL
          AND cc_closed_date_sk IS NOT NULL
    ),
    set_intersect AS (
        SELECT cc_call_center_sk FROM set1
        INTERSECT
        SELECT cc_call_center_sk FROM set2
    ),
    set_exclude AS (
        SELECT cc_call_center_sk
        FROM call_center
        WHERE cc_sq_ft < 0
    ),
    final_keys AS (
        SELECT cc_call_center_sk FROM set_intersect
        EXCEPT
        SELECT cc_call_center_sk FROM set_exclude
    ),
    agg AS (
        SELECT
            cc.cc_country AS country,
            d.d_year AS year,
            COUNT(DISTINCT cc.cc_call_center_sk) AS cnt_centers,
            SUM(cc.cc_sq_ft) AS total_sq_ft,
            AVG(cc.cc_employees) AS avg_employees,
            MIN(cc.cc_gmt_offset) AS min_gmt_offset,
            MAX(cc.cc_gmt_offset) AS max_gmt_offset
        FROM final_keys fk
        JOIN call_center cc
            ON fk.cc_call_center_sk = cc.cc_call_center_sk
        LEFT OUTER JOIN date_dim d
            ON cc.cc_open_date_sk = d.d_date_sk
        WHERE d.d_day_name = 'Monday'
          AND d.d_quarter_name = '1901Q4'
          AND cc.cc_market_manager = 'Gary Colburn'
        GROUP BY cc.cc_country, d.d_year
    )
SELECT
    country,
    year,
    cnt_centers,
    total_sq_ft,
    avg_employees,
    min_gmt_offset,
    max_gmt_offset,
    CASE WHEN total_sq_ft > 10000000 THEN 'LARGE' ELSE 'SMALL' END AS size_category,
    ROW_NUMBER() OVER (PARTITION BY country ORDER BY total_sq_ft DESC) AS country_sqft_rank
FROM agg
ORDER BY total_sq_ft DESC, cnt_centers DESC
LIMIT 100

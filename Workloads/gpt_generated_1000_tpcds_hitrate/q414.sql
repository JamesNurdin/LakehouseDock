WITH
    filtered_store AS (
        SELECT
            s_store_sk,
            s_store_name,
            s_floor_space,
            s_country,
            s_state,
            s_gmt_offset,
            s_tax_percentage,
            s_closed_date_sk
        FROM store
        WHERE s_country = 'United States'
          AND s_floor_space > 8000000
          AND s_state IN ('CA', 'TX', 'NY')
          AND s_gmt_offset BETWEEN -5.00 AND 5.00
          AND s_tax_percentage < 10.00
    ),
    joined_data AS (
        SELECT
            fs.s_store_sk,
            fs.s_store_name,
            fs.s_floor_space,
            fs.s_state,
            d.d_year,
            d.d_quarter_name,
            d.d_fy_week_seq
        FROM filtered_store AS fs
        JOIN date_dim AS d
          ON fs.s_closed_date_sk = d.d_date_sk
        WHERE d.d_fy_week_seq <= (
                SELECT MAX(d_fy_week_seq)
                FROM date_dim
            ) - 2
          AND fs.s_store_sk IN (
                SELECT s_store_sk
                FROM store
                WHERE s_market_id = 3
            )
    ),
    agg AS (
        SELECT
            s_state,
            d_year,
            d_quarter_name,
            COUNT(DISTINCT s_store_sk) AS store_cnt,
            SUM(s_floor_space) AS total_floor_space,
            AVG(s_floor_space) AS avg_floor_space,
            MIN(s_floor_space) AS min_floor_space,
            MAX(s_floor_space) AS max_floor_space
        FROM joined_data
        GROUP BY CUBE (s_state, d_year, d_quarter_name)
        HAVING COUNT(DISTINCT s_store_sk) > 0
    )
SELECT
    s_state,
    d_year,
    d_quarter_name,
    store_cnt,
    total_floor_space,
    avg_floor_space,
    min_floor_space,
    max_floor_space,
    LAG(total_floor_space) OVER (PARTITION BY s_state ORDER BY d_year) AS prev_state_total_floor_space
FROM agg
ORDER BY s_state NULLS LAST, d_year NULLS LAST
LIMIT 100

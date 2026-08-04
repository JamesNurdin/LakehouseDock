WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_fy_quarter_seq,
        d.d_following_holiday,
        wp.wp_web_page_sk,
        wp.wp_char_count,
        wp.wp_url,
        wp.wp_type
    FROM web_page wp
    RIGHT OUTER JOIN date_dim d
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE wp.wp_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
      AND wp.wp_char_count BETWEEN 1000 AND 8000
      AND d.d_following_holiday = 'N'
      AND d.d_fy_quarter_seq IN (14, 15, 16, 17)
      AND wp.wp_web_page_sk NOT IN (
          SELECT wp_web_page_sk FROM web_page WHERE wp_char_count > 7000
      )
),
agg1 AS (
    SELECT
        d_year,
        d_fy_quarter_seq,
        SUM(COALESCE(wp_char_count, 0)) AS total_char_sum,
        COUNT(wp_web_page_sk) AS page_cnt
    FROM base
    GROUP BY d_year, d_fy_quarter_seq
),
union_set AS (
    SELECT d_year, total_char_sum FROM agg1
    UNION
    SELECT d_year, total_char_sum * 0.9 FROM agg1 WHERE total_char_sum > 10000
),
final_agg AS (
    SELECT
        u.d_year,
        AVG(u.total_char_sum) AS avg_char_sum,
        SUM(u.total_char_sum) AS sum_char_sum
    FROM union_set u
    GROUP BY u.d_year
),
result AS (
    SELECT
        f.d_year,
        f.avg_char_sum,
        f.sum_char_sum
    FROM final_agg f
    EXCEPT
    SELECT
        d_year,
        avg_char_sum,
        sum_char_sum
    FROM final_agg
    WHERE d_year IN (SELECT d_year FROM date_dim WHERE d_current_year = '2000')
)
SELECT *
FROM result
ORDER BY avg_char_sum DESC
OFFSET 0
LIMIT 100

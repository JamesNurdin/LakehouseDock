WITH agg AS (
    SELECT
        ib.ib_income_band_sk AS income_band_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CONCAT(CAST(d_creation.d_year AS VARCHAR), '-', LPAD(CAST(d_creation.d_moy AS VARCHAR), 2, '0')) AS creation_month,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
        SUM(wp.wp_char_count) AS total_chars,
        AVG(wp.wp_link_count) AS avg_links,
        SUM(CASE WHEN wp.wp_type = 'article' THEN 1 ELSE 0 END) AS article_cnt,
        AVG(date_diff('day', d_creation.d_date, d_access.d_date)) AS avg_lifespan_days
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_creation.d_year = 2023
      AND d_access.d_year = 2023
      AND d_access.d_qoy = 1
      AND c.c_birth_month IN (5, 6, 7)
      AND wp.wp_type IN ('article', 'blog')
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, d_creation.d_year, d_creation.d_moy
    HAVING COUNT(DISTINCT wp.wp_web_page_sk) > 5
)
SELECT
    income_band_id,
    ib_lower_bound,
    ib_upper_bound,
    creation_month,
    page_cnt,
    total_chars,
    avg_links,
    article_cnt,
    avg_lifespan_days,
    RANK() OVER (PARTITION BY income_band_id ORDER BY total_chars DESC) AS char_rank
FROM agg
ORDER BY income_band_id, char_rank
LIMIT 200

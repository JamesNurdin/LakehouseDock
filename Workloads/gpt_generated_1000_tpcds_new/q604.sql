WITH
    sampled_date AS (
        SELECT *
        FROM date_dim
        TABLESAMPLE BERNOULLI (10)
        WHERE d_year BETWEEN 1999 AND 2002
          AND d_quarter_name = 'Q1'
          AND d_fy_quarter_seq IN (4, 8, 9)
          AND d_current_week = 'N'
          AND d_dom IN (2, 11, 16)
    ),
    union_date AS (
        SELECT d_date_sk, d_year, d_month_seq, d_day_name
        FROM sampled_date
        WHERE d_month_seq = 1
        UNION DISTINCT
        SELECT d_date_sk, d_year, d_month_seq, d_day_name
        FROM sampled_date
        WHERE d_month_seq = 2
    ),
    filtered_web AS (
        SELECT *
        FROM web_site
        WHERE web_state = 'CA'
          AND web_gmt_offset = -8.00
          AND web_tax_percentage > 5.00
          AND web_company_name LIKE '%able%'
          AND web_site_sk IN (
                SELECT d_date_sk
                FROM date_dim
                WHERE d_fy_quarter_seq = 9
          )
    )
SELECT
    d.d_year,
    w.web_state,
    COUNT(DISTINCT w.web_site_id) AS site_count,
    SUM(w.web_gmt_offset) AS total_gmt_offset,
    AVG(w.web_tax_percentage) AS avg_tax_pct,
    MIN(w.web_open_date_sk) AS min_open_sk,
    MAX(w.web_close_date_sk) AS max_close_sk,
    LAG(COUNT(DISTINCT w.web_site_id)) OVER (PARTITION BY d.d_year ORDER BY w.web_state) AS lag_site_count
FROM union_date d
FULL OUTER JOIN filtered_web w
    ON d.d_date_sk = w.web_open_date_sk OR d.d_date_sk = w.web_close_date_sk
GROUP BY d.d_year, w.web_state
ORDER BY d.d_year DESC, site_count DESC
LIMIT 100

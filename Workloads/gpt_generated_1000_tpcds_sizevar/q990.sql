/* goal: Rank website openings per company and compare them across fiscal quarters, using a sampled date dimension, window functions, CASE logic, and various set operations */
WITH sampled_dates AS (
    SELECT
        d_date_sk,
        d_date_id,
        d_date,
        d_year,
        d_fy_quarter_seq,
        d_current_quarter
    FROM date_dim
    TABLESAMPLE BERNOULLI (10)   -- approximate 10 % random sample
),
site_open AS (
    SELECT
        w.web_site_id,
        w.web_company_id,
        w.web_rec_start_date,
        w.web_class,
        d.d_date_id,
        d.d_year,
        d.d_fy_quarter_seq,
        d.d_current_quarter,
        CASE WHEN d.d_current_quarter = 'Y' THEN 'Current' ELSE 'Past' END AS quarter_status,
        ROW_NUMBER() OVER (PARTITION BY w.web_company_id ORDER BY d.d_date) AS site_open_seq
    FROM sampled_dates d
    FULL OUTER JOIN web_site w
        ON d.d_date_sk = w.web_open_date_sk
    WHERE d.d_fy_quarter_seq IN (5, 6, 9)
      AND d.d_current_quarter = 'Y'
      AND w.web_rec_start_date >= DATE '1999-01-01'
      AND w.web_class = 'Unknown'
),
year_grid AS (
    SELECT yr
    FROM (VALUES 1999, 2000, 2001, 2002) AS t(yr)
),
crossed AS (
    SELECT
        s.web_site_id,
        s.web_company_id,
        s.web_rec_start_date,
        s.web_class,
        s.d_date_id,
        s.d_year,
        s.d_fy_quarter_seq,
        s.d_current_quarter,
        s.quarter_status,
        s.site_open_seq,
        y.yr AS target_year
    FROM site_open s
    CROSS JOIN year_grid y
    WHERE s.d_year = y.yr
),
final_part AS (
    SELECT
        web_site_id,
        web_company_id,
        d_year,
        target_year,
        quarter_status,
        site_open_seq,
        CASE WHEN site_open_seq = 1 THEN 'First' ELSE 'Later' END AS opening_rank_desc
    FROM crossed
    WHERE site_open_seq <= 5
)
SELECT
    fp.web_site_id,
    fp.web_company_id,
    fp.d_year,
    fp.target_year,
    fp.quarter_status,
    fp.site_open_seq,
    fp.opening_rank_desc
FROM (
    SELECT
        web_site_id,
        web_company_id,
        d_year,
        target_year,
        quarter_status,
        site_open_seq,
        opening_rank_desc
    FROM final_part
    UNION DISTINCT
    SELECT
        web_site_id,
        web_company_id,
        d_year,
        target_year,
        quarter_status,
        site_open_seq,
        opening_rank_desc
    FROM final_part
    WHERE opening_rank_desc = 'First'
) AS fp
ORDER BY fp.d_year DESC, fp.site_open_seq
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY

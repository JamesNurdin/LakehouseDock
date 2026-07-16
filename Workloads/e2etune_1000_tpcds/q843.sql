WITH site_info AS (
    SELECT
        ws.web_site_id,
        ws.web_tax_percentage,
        open_d.d_fy_year AS open_fy_year,
        open_d.d_fy_quarter_seq AS open_fy_quarter_seq,
        open_d.d_holiday AS open_holiday,
        close_d.d_holiday AS close_holiday,
        open_d.d_date AS open_date,
        close_d.d_date AS close_date,
        date_diff('day', open_d.d_date, close_d.d_date) AS days_open
    FROM web_site ws
    JOIN date_dim open_d
        ON ws.web_open_date_sk = open_d.d_date_sk
    JOIN date_dim close_d
        ON ws.web_close_date_sk = close_d.d_date_sk
    WHERE open_d.d_holiday = 'Y'
      AND (close_d.d_holiday = 'N' OR close_d.d_holiday IS NULL)
),
agg AS (
    SELECT
        open_fy_year,
        open_fy_quarter_seq,
        COUNT(*) AS site_count,
        AVG(web_tax_percentage) AS avg_tax_percentage,
        AVG(days_open) AS avg_days_open
    FROM site_info
    GROUP BY open_fy_year, open_fy_quarter_seq
    HAVING COUNT(*) > 5
)
SELECT
    open_fy_year,
    open_fy_quarter_seq,
    site_count,
    avg_tax_percentage,
    avg_days_open,
    ROW_NUMBER() OVER (ORDER BY avg_tax_percentage DESC) AS tax_rank
FROM agg
ORDER BY tax_rank

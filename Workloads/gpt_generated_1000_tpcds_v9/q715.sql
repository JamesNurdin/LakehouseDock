WITH base_sites AS (
    SELECT
        ws.web_site_sk,
        ws.web_company_id,
        ws.web_company_name,
        d_open.d_year AS open_year,
        d_open.d_month_seq AS open_month_seq,
        d_open.d_date AS open_date,
        d_close.d_date AS close_date,
        date_diff('day', d_open.d_date, d_close.d_date) AS duration_days,
        ws.web_gmt_offset,
        mkt.first_word,
        substr(ws.web_name, 1, 10) AS name_prefix,
        CONCAT(ws.web_street_number, ' ', ws.web_street_name, ', ', ws.web_city, ', ', ws.web_state) AS full_address
    FROM web_site ws
    JOIN date_dim d_open
        ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    CROSS JOIN LATERAL (
        SELECT regexp_extract(ws.web_mkt_desc, '^([A-Za-z]+)', 1) AS first_word
    ) AS mkt
    WHERE regexp_like(ws.web_mkt_desc, '(?i)electric')
      AND ws.web_suite_number LIKE 'Suite %'
      AND ws.web_suite_number NOT LIKE '%U%'
      AND d_open.d_current_month = 'Y'
)
SELECT
    bs.web_company_id,
    bs.web_company_name,
    bs.open_year,
    bs.open_month_seq,
    bs.first_word,
    COUNT(*) AS site_count,
    AVG(bs.web_gmt_offset) AS avg_gmt_offset,
    AVG(bs.duration_days) AS avg_duration_days,
    ROW_NUMBER() OVER (PARTITION BY bs.web_company_id ORDER BY bs.open_year, bs.open_month_seq) AS company_site_rank,
    MIN(substr(bs.web_company_name, 1, 5)) AS company_prefix,
    MIN(bs.name_prefix) AS sample_name_prefix
FROM base_sites bs
GROUP BY
    bs.web_company_id,
    bs.web_company_name,
    bs.open_year,
    bs.open_month_seq,
    bs.first_word
ORDER BY
    bs.web_company_id,
    bs.open_year,
    bs.open_month_seq,
    bs.first_word
LIMIT 100

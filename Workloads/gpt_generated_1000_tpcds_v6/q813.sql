WITH returns_agg AS (
    SELECT
        wr_returned_date_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt_returns
    FROM web_returns
    WHERE wr_return_amt > 0
    GROUP BY wr_returned_date_sk
),
date_ret AS (
    SELECT
        r.wr_returned_date_sk,
        r.total_return_amt,
        r.cnt_returns,
        d.d_year,
        d.d_quarter_seq
    FROM returns_agg r
    JOIN date_dim d
        ON r.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_current_day = 'N'
),
site_filtered AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        ws.web_street_type,
        ws.web_suite_number,
        ws.web_open_date_sk,
        d.d_year AS open_year,
        d.d_quarter_seq AS open_quarter
    FROM web_site ws
    JOIN date_dim d
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE regexp_like(ws.web_suite_number, '^Suite [0-9]+$')
      AND ws.web_street_type LIKE '%Dr%'
)
SELECT DISTINCT
    s.web_name,
    s.web_street_type,
    s.web_suite_number,
    dr.d_year,
    dr.d_quarter_seq,
    dr.total_return_amt,
    dr.cnt_returns,
    regexp_extract(s.web_suite_number, '([0-9]+)') AS suite_number_extracted,
    concat(s.web_name, ' - ', s.web_suite_number) AS site_suite_label
FROM site_filtered s
JOIN date_ret dr
    ON s.open_year = dr.d_year
ORDER BY dr.total_return_amt DESC
LIMIT 100

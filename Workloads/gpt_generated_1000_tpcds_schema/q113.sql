WITH
    open_agg AS (
        SELECT
            ws.web_open_date_sk AS open_date_sk,
            ws.web_state,
            COUNT(*) AS site_cnt,
            SUM(ws.web_tax_percentage) AS tax_sum
        FROM web_site ws
        WHERE ws.web_open_date_sk IS NOT NULL
          AND ws.web_manager IS NOT NULL
          AND ws.web_state IN ('CA', 'TX', 'NY', 'FL')
          AND ws.web_gmt_offset BETWEEN -5.00 AND 5.00
        GROUP BY ws.web_open_date_sk, ws.web_state
    ),
    close_agg AS (
        SELECT
            ws.web_close_date_sk AS close_date_sk,
            ws.web_state,
            COUNT(*) AS site_cnt,
            AVG(ws.web_tax_percentage) AS tax_sum
        FROM web_site ws
        WHERE ws.web_close_date_sk IS NOT NULL
          AND ws.web_manager IS NOT NULL
          AND ws.web_state IN ('CA', 'TX', 'NY', 'FL')
          AND ws.web_gmt_offset BETWEEN -5.00 AND 5.00
        GROUP BY ws.web_close_date_sk, ws.web_state
    ),
    union_data AS (
        SELECT
            d.d_year,
            o.web_state,
            o.site_cnt AS open_site_cnt,
            o.tax_sum AS open_tax_sum,
            d.d_month_seq,
            (SELECT COUNT(*) FROM web_site ws2 WHERE ws2.web_state = o.web_state) AS total_sites_in_state
        FROM open_agg o
        JOIN date_dim d ON d.d_date_sk = o.open_date_sk
        WHERE d.d_month_seq BETWEEN 1 AND 12
          AND d.d_qoy = 2
          AND d.d_day_name = 'Monday'
          AND d.d_holiday = 'N'
        UNION DISTINCT
        SELECT
            d.d_year,
            c.web_state,
            c.site_cnt AS open_site_cnt,
            c.tax_sum AS open_tax_sum,
            d.d_month_seq,
            (SELECT COUNT(*) FROM web_site ws2 WHERE ws2.web_state = c.web_state) AS total_sites_in_state
        FROM close_agg c
        JOIN date_dim d ON d.d_date_sk = c.close_date_sk
        WHERE d.d_month_seq BETWEEN 1 AND 12
          AND d.d_qoy = 2
          AND d.d_day_name = 'Monday'
          AND d.d_holiday = 'N'
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY d_year DESC, web_state) AS rn,
    d_year,
    web_state,
    open_site_cnt,
    open_tax_sum,
    d_month_seq,
    total_sites_in_state
FROM union_data
ORDER BY rn

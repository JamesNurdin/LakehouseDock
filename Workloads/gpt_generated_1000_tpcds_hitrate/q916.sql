WITH sampled_ws AS (
        SELECT *
        FROM web_site TABLESAMPLE BERNOULLI (10)
    ),
    joined AS (
        SELECT
            ws.web_site_id,
            ws.web_name,
            ws.web_state,
            ws.web_gmt_offset,
            ws.web_tax_percentage,
            ws.web_suite_number,
            ws.web_company_name,
            d_open.d_date,
            d_open.d_year,
            ROW_NUMBER() OVER (PARTITION BY ws.web_state ORDER BY ws.web_gmt_offset DESC) AS rn_state
        FROM sampled_ws ws
        JOIN date_dim d_open
          ON ws.web_open_date_sk = d_open.d_date_sk
        WHERE d_open.d_year = 2000
          AND d_open.d_month_seq BETWEEN 1200 AND 1300
          AND ws.web_gmt_offset = -5.00
          AND ws.web_state = 'CA'
          AND ws.web_suite_number LIKE 'Suite %'
          AND ws.web_company_name NOT LIKE 'pri%'
          AND ws.web_site_sk NOT IN (
                SELECT web_site_sk
                FROM web_site
                WHERE web_close_date_sk IS NULL
          )
    )
SELECT
    web_site_id,
    web_name,
    web_state,
    web_gmt_offset,
    CASE WHEN web_gmt_offset < 0 THEN 'West' ELSE 'Other' END AS region,
    d_date,
    rn_state,
    (
        SELECT COUNT(*)
        FROM date_dim d2
        WHERE d2.d_year = joined.d_year
    ) AS days_in_year,
    (
        SELECT MAX(d_month_seq)
        FROM date_dim d3
        WHERE d3.d_year = joined.d_year
    ) AS max_month_seq_year,
    metric
FROM joined
CROSS JOIN UNNEST(ARRAY[web_gmt_offset, web_tax_percentage]) AS t(metric)
WHERE rn_state <= 5
LIMIT 100

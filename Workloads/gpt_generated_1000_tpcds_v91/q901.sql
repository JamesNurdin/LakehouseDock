WITH site_dates AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        ws.web_state,
        ws.web_gmt_offset,
        ws.web_tax_percentage,
        ws.web_company_id,
        ws.web_street_number,
        ws.web_suite_number,
        ws.web_open_date_sk,
        ws.web_close_date_sk,
        od.d_date AS open_date,
        od.d_year AS open_year,
        od.d_quarter_name AS open_quarter,
        cd.d_date AS close_date,
        cd.d_year AS close_year,
        cd.d_quarter_name AS close_quarter,
        ARRAY[ws.web_gmt_offset, ws.web_tax_percentage] AS metrics_array
    FROM web_site ws
    JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
    JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
    WHERE ws.web_company_id IN (2, 3, 5, 6)
      AND ws.web_street_number IN ('784', '358', '841')
      AND ws.web_suite_number IN ('Suite 260', 'Suite 460')
      AND od.d_year = 2001
      AND cd.d_quarter_name = 'Q1'
),
unnested_metrics AS (
    SELECT
        sd.*,
        m.metric_value,
        CASE WHEN m.ordinality = 1 THEN 'GMT_OFFSET' ELSE 'TAX_PERCENTAGE' END AS metric_type
    FROM site_dates sd
    CROSS JOIN UNNEST(sd.metrics_array) WITH ORDINALITY AS m(metric_value, ordinality)
)
SELECT
    un.metric_type,
    un.web_state,
    un.open_year,
    COUNT(DISTINCT un.web_site_sk) AS site_count,
    SUM(un.metric_value) AS total_metric,
    AVG(un.metric_value) AS avg_metric,
    MIN(un.metric_value) AS min_metric,
    MAX(un.metric_value) AS max_metric,
    CASE WHEN AVG(un.metric_value) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS avg_sign,
    ROW_NUMBER() OVER (ORDER BY SUM(un.metric_value) DESC) AS row_num
FROM unnested_metrics un
WHERE un.metric_value IS NOT NULL
GROUP BY
    un.metric_type,
    un.web_state,
    un.open_year
ORDER BY total_metric DESC
LIMIT 100

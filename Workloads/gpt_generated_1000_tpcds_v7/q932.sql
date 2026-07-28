WITH site_open_days AS (
  SELECT
    ws.web_site_id,
    ws.web_name,
    ws.web_company_id,
    od.d_year AS open_year,
    od.d_date AS open_date,
    cd.d_date AS close_date,
    DATE_DIFF('day', od.d_date, cd.d_date) + 1 AS open_span_days,
    ws.web_gmt_offset,
    ws.web_tax_percentage
  FROM web_site ws
  JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
  JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
  WHERE od.d_year = 2000
    AND cd.d_year = 2002
    AND ws.web_company_id IN (1, 2, 3, 4)
    AND ws.web_state = 'CA'
    AND ws.web_mkt_class = 'A'
    AND ws.web_tax_percentage > 0.05
),
company_agg AS (
  SELECT
    sod.web_company_id,
    COUNT(DISTINCT sod.web_site_id) AS site_cnt,
    SUM(sod.open_span_days) AS total_open_days,
    AVG(sod.open_span_days) AS avg_open_days
  FROM site_open_days sod
  GROUP BY sod.web_company_id
),
final_calc AS (
  SELECT
    ca.web_company_id,
    ca.site_cnt,
    ca.total_open_days,
    ca.avg_open_days,
    (SELECT AVG(total_open_days) FROM company_agg) AS overall_avg_days
  FROM company_agg ca
  WHERE ca.total_open_days > (SELECT AVG(total_open_days) FROM company_agg)
)
SELECT
  fc.web_company_id,
  fc.site_cnt,
  fc.total_open_days,
  fc.avg_open_days,
  fc.overall_avg_days,
  RANK() OVER (ORDER BY fc.total_open_days DESC) AS rank_by_total_days,
  SUM(fc.total_open_days) OVER (
    PARTITION BY CASE WHEN fc.total_open_days > fc.overall_avg_days THEN 'ABOVE' ELSE 'BELOW' END
  ) AS sum_by_group
FROM final_calc fc
ORDER BY fc.total_open_days DESC, fc.web_company_id

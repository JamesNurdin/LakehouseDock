WITH joined AS (
  SELECT
    ws.web_site_sk,
    ws.web_site_id,
    ws.web_name,
    ws.web_state,
    ws.web_class,
    ws.web_tax_percentage,
    ws.web_gmt_offset,
    od.d_date AS open_date,
    od.d_year AS open_year,
    od.d_month_seq AS open_month_seq,
    cd.d_date AS close_date,
    cd.d_year AS close_year,
    cd.d_month_seq AS close_month_seq,
    cd.d_holiday AS close_holiday
  FROM web_site ws
  JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
  JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
  WHERE od.d_year = 2000
    AND od.d_month_seq BETWEEN 1 AND 12
    AND cd.d_holiday = 'N'
    AND ws.web_class = 'Unknown'
    AND ws.web_tax_percentage > 5.0
    AND ws.web_gmt_offset >= -5.00
),
agg AS (
  SELECT
    j.web_state,
    j.web_class,
    j.open_year,
    COUNT(*) AS site_cnt,
    AVG(j.web_tax_percentage) AS avg_tax,
    MIN(j.open_date) AS earliest_open_date,
    MAX(j.close_date) AS latest_close_date
  FROM joined j
  GROUP BY j.web_state, j.web_class, j.open_year
)
SELECT
  a.web_state,
  a.web_class,
  a.open_year,
  a.site_cnt,
  a.avg_tax,
  a.earliest_open_date,
  a.latest_close_date,
  SUM(a.site_cnt) OVER (PARTITION BY a.web_state ORDER BY a.avg_tax ROWS UNBOUNDED PRECEDING) AS cum_site_cnt,
  RANK() OVER (PARTITION BY a.web_state ORDER BY a.site_cnt DESC) AS state_rank
FROM agg a
ORDER BY a.web_state, a.site_cnt DESC
LIMIT 100

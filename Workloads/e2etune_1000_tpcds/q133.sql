WITH warehouse_band AS (
  SELECT
    w.w_warehouse_sk,
    w.w_county,
    w.w_state,
    w.w_warehouse_sq_ft,
    ib.ib_income_band_sk
  FROM warehouse w
  JOIN income_band ib
    ON w.w_warehouse_sq_ft BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
  WHERE w.w_warehouse_sq_ft > 500000
),
agg AS (
  SELECT
    wb.w_county,
    wb.ib_income_band_sk,
    COUNT(DISTINCT wb.w_warehouse_sk) AS warehouse_cnt,
    SUM(wb.w_warehouse_sq_ft) AS total_sq_ft,
    AVG(wb.w_warehouse_sq_ft) AS avg_sq_ft,
    AVG(ws.web_tax_percentage) AS avg_web_tax_pct
  FROM warehouse_band wb
  JOIN web_site ws
    ON wb.w_state = ws.web_state
  WHERE ws.web_tax_percentage IS NOT NULL
  GROUP BY wb.w_county, wb.ib_income_band_sk
  HAVING COUNT(DISTINCT wb.w_warehouse_sk) >= 2
)
SELECT
  a.w_county,
  a.ib_income_band_sk,
  a.warehouse_cnt,
  a.total_sq_ft,
  a.avg_sq_ft,
  a.avg_web_tax_pct,
  RANK() OVER (PARTITION BY a.ib_income_band_sk ORDER BY a.total_sq_ft DESC) AS county_rank_in_band,
  SUM(a.total_sq_ft) OVER (
    PARTITION BY a.ib_income_band_sk
    ORDER BY a.total_sq_ft DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cum_total_sq_ft
FROM agg a
ORDER BY a.ib_income_band_sk, county_rank_in_band
LIMIT 100

WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_ext_sales_price,
    cs.cs_sold_date_sk,
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    w.w_gmt_offset,
    sr.sr_net_loss,
    r.r_reason_id
  FROM catalog_sales cs
  FULL OUTER JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN store_returns sr
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  WHERE ib.ib_lower_bound >= 30000
    AND w.w_gmt_offset BETWEEN -5.00 AND 2.00
    AND sm.sm_type = 'AIR'
),
agg AS (
  SELECT
    ib_upper_bound AS income_upper,
    sm_type AS ship_type,
    SUM(cs_net_profit) AS total_profit,
    SUM(cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs_order_number) AS order_cnt
  FROM base
  GROUP BY ROLLUP (ib_upper_bound, sm_type)
),
avg_profit AS (
  SELECT AVG(total_profit) AS avg_total_profit FROM agg
),
final AS (
  SELECT
    agg.income_upper,
    agg.ship_type,
    agg.total_profit,
    agg.total_sales,
    agg.order_cnt,
    avg_profit.avg_total_profit,
    (SELECT COUNT(*) FROM store_returns WHERE sr_net_loss > 0) AS loss_record_cnt
  FROM agg
  CROSS JOIN (SELECT sm_type FROM ship_mode WHERE sm_type = 'AIR' LIMIT 1) dim
  CROSS JOIN (VALUES 1, 2) AS v(num)
  CROSS JOIN avg_profit
  WHERE agg.total_profit > 1000
)
SELECT income_upper, ship_type, total_profit, total_sales, order_cnt, avg_total_profit, loss_record_cnt
FROM final
WHERE ship_type IS NOT NULL
UNION
SELECT income_upper, ship_type, total_profit, total_sales, order_cnt, avg_total_profit, loss_record_cnt
FROM final
WHERE total_sales > 5000
ORDER BY income_upper NULLS LAST, ship_type
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY

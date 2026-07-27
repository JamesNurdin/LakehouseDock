WITH cs_agg AS (
  SELECT
    cs_promo_sk,
    cs_warehouse_sk,
    cs_bill_hdemo_sk,
    cs_sold_time_sk,
    SUM(cs_ext_sales_price) AS sum_sales_price,
    SUM(cs_quantity) AS total_quantity,
    AVG(cs_net_profit) AS avg_profit
  FROM catalog_sales
  WHERE cs_quantity > 5
    AND cs_wholesale_cost > 10
    AND cs_sold_date_sk BETWEEN 2450815 AND 2450825
  GROUP BY cs_promo_sk, cs_warehouse_sk, cs_bill_hdemo_sk, cs_sold_time_sk
),
ws_agg AS (
  SELECT
    ws_promo_sk,
    ws_warehouse_sk,
    ws_bill_hdemo_sk,
    ws_sold_time_sk,
    SUM(ws_ext_sales_price) AS ws_sum_sales_price,
    SUM(ws_quantity) AS ws_total_quantity,
    AVG(ws_net_profit) AS ws_avg_profit
  FROM web_sales
  WHERE ws_quantity > 3
    AND ws_wholesale_cost > 5
    AND ws_sold_date_sk BETWEEN 2450815 AND 2450825
  GROUP BY ws_promo_sk, ws_warehouse_sk, ws_bill_hdemo_sk, ws_sold_time_sk
)
SELECT
  p.p_promo_id,
  w.w_warehouse_name,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  hd.hd_buy_potential,
  SUM(cs_agg.sum_sales_price) AS catalog_total_sales,
  SUM(ws_agg.ws_sum_sales_price) AS web_total_sales,
  SUM(cs_agg.total_quantity + ws_agg.ws_total_quantity) AS total_units_sold,
  CASE
    WHEN (AVG(cs_agg.avg_profit) + AVG(ws_agg.ws_avg_profit)) / 2 > 100 THEN 'HIGH'
    ELSE 'NORMAL'
  END AS profit_category,
  MAX(t_c.t_hour) AS latest_catalog_hour,
  MAX(t_w.t_hour) AS latest_web_hour
FROM cs_agg
JOIN ws_agg
  ON cs_agg.cs_promo_sk = ws_agg.ws_promo_sk
  AND cs_agg.cs_warehouse_sk = ws_agg.ws_warehouse_sk
JOIN promotion p
  ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
  ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
  ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN time_dim t_c
  ON cs_agg.cs_sold_time_sk = t_c.t_time_sk
JOIN time_dim t_w
  ON ws_agg.ws_sold_time_sk = t_w.t_time_sk
WHERE p.p_channel_event = 'N'
  AND p.p_channel_catalog = 'N'
  AND hd.hd_dep_count BETWEEN 1 AND 5
  AND hd.hd_buy_potential IN ('1001-5000', '>10000')
  AND w.w_state = 'CA'
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = p.p_promo_sk
          AND p2.p_discount_active = 'Y'
      )
GROUP BY
  p.p_promo_id,
  w.w_warehouse_name,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  hd.hd_buy_potential
ORDER BY catalog_total_sales DESC
LIMIT 100

WITH sales_agg AS (
  SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
      WHEN cs.cs_net_profit > 1000 THEN 'High'
      WHEN cs.cs_net_profit > 0 THEN 'Medium'
      ELSE 'Low'
    END AS profit_category,
    SUM(cs.cs_net_profit) AS profit_sum,
    SUM(cs.cs_quantity) AS qty_sum,
    COUNT(*) AS txn_cnt
  FROM catalog_sales cs
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  WHERE cs.cs_net_paid_inc_ship_tax > 1000
    AND cs.cs_coupon_amt < 500
    AND hd.hd_vehicle_count >= 1
    AND hd.hd_buy_potential IN ('1001-5000', '>10000')
    AND i.i_units IN ('Lb', 'Dozen')
    AND i.i_wholesale_cost BETWEEN 0.5 AND 20
    AND EXISTS (
      SELECT 1
      FROM promotion p
      WHERE p.p_promo_sk = cs.cs_promo_sk
        AND p.p_item_sk = cs.cs_item_sk
        AND p.p_discount_active = 'Y'
    )
  GROUP BY ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           CASE
             WHEN cs.cs_net_profit > 1000 THEN 'High'
             WHEN cs.cs_net_profit > 0 THEN 'Medium'
             ELSE 'Low'
           END
)
SELECT
  ib_income_band_sk,
  CONCAT(CAST(ib_lower_bound AS VARCHAR), '-', CAST(ib_upper_bound AS VARCHAR)) AS income_range,
  SUM(profit_sum) AS total_profit,
  SUM(qty_sum) AS total_quantity,
  SUM(txn_cnt) AS total_transactions,
  AVG(profit_sum) AS avg_profit_per_category
FROM sales_agg
GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
ORDER BY total_profit DESC
LIMIT 100

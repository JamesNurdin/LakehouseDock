WITH sales_sample AS (
  SELECT *
  FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
joined AS (
  SELECT
    cs.cs_item_sk,
    cs.cs_ship_mode_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_coupon_amt,
    i.i_category,
    i.i_current_price,
    i.i_wholesale_cost,
    cd.cd_gender,
    sm.sm_carrier,
    sm.sm_contract
  FROM sales_sample cs
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE i.i_current_price BETWEEN 5 AND 30
    AND i.i_wholesale_cost < 10
    AND cd.cd_gender = 'M'
    AND sm.sm_carrier IN ('AIRBORNE', 'USPS')
    AND cs.cs_coupon_amt > 100
),
agg1 AS (
  SELECT
    i_category,
    sm_carrier,
    COUNT(*) AS sales_cnt,
    SUM(cs_net_profit) AS total_profit,
    AVG(cs_quantity) AS avg_qty,
    CASE
      WHEN SUM(cs_net_profit) > 0 THEN 'POS'
      ELSE 'NEG'
    END AS profit_sign
  FROM joined
  GROUP BY i_category, sm_carrier
),
final AS (
  SELECT
    i_category,
    COUNT(*) AS carrier_cnt,
    SUM(total_profit) AS category_profit,
    AVG(avg_qty) AS avg_quantity,
    MAX(CASE WHEN profit_sign = 'POS' THEN total_profit ELSE NULL END) AS max_positive_profit
  FROM agg1
  GROUP BY i_category
  HAVING SUM(total_profit) > 500
)
SELECT
  i_category,
  carrier_cnt,
  category_profit,
  avg_quantity,
  max_positive_profit
FROM final
ORDER BY category_profit DESC
LIMIT 100

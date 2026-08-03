WITH
  joined AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_net_profit,
      cs.cs_ext_sales_price,
      cs.cs_quantity,
      cs.cs_call_center_sk,
      cs.cs_ship_mode_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_hdemo_sk,
      i.i_category,
      i.i_category_id,
      i.i_units,
      cc.cc_state,
      sm.sm_type,
      hd.hd_income_band_sk,
      ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_category_id IN (1, 3, 7)
      AND cs.cs_ext_sales_price > 1000
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND ib.ib_upper_bound > 50000
  ),
  order_exceptions AS (
    SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 500
    EXCEPT
    SELECT cs_order_number FROM catalog_sales WHERE cs_ext_discount_amt = 0
  ),
  final_set AS (
    SELECT
      j.cs_order_number,
      j.cs_item_sk,
      j.i_category,
      j.cs_net_profit,
      j.cs_ext_sales_price,
      j.cs_quantity,
      j.cc_state,
      j.sm_type,
      j.ib_upper_bound,
      RANK() OVER (PARTITION BY j.i_category ORDER BY j.cs_net_profit DESC) AS profit_rank,
      (
        SELECT SUM(cs3.cs_ext_sales_price)
        FROM catalog_sales cs3
        WHERE cs3.cs_item_sk = j.cs_item_sk
      ) AS total_item_sales
    FROM joined j
    WHERE j.cs_order_number NOT IN (SELECT cs_order_number FROM order_exceptions)
  )
SELECT
  cs_order_number,
  cs_item_sk,
  i_category,
  cs_net_profit,
  cs_ext_sales_price,
  profit_rank,
  total_item_sales
FROM final_set
WHERE profit_rank <= 10
UNION
SELECT
  cs_order_number,
  cs_item_sk,
  i_category,
  cs_net_profit,
  cs_ext_sales_price,
  profit_rank,
  total_item_sales
FROM final_set
WHERE cs_ext_sales_price > (
  SELECT AVG(cs_ext_sales_price) FROM final_set
)
ORDER BY cs_net_profit DESC, cs_order_number
LIMIT 100

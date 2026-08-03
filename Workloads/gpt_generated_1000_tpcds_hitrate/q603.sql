WITH
  agg_refunded AS (
    SELECT
      cr_item_sk,
      cr_reason_sk,
      cr_refunded_hdemo_sk,
      cr_catalog_page_sk,
      SUM(cr_return_amount) AS sum_return_amount,
      AVG(cr_return_tax) AS avg_return_tax,
      COUNT(*) AS return_cnt
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_tax > 5
      AND cr_return_quantity >= 1
      AND cr_return_amount > 10
      AND cr_return_ship_cost < 50
      AND cr_store_credit BETWEEN 0 AND 20
      AND cr_fee < 5
    GROUP BY cr_item_sk, cr_reason_sk, cr_refunded_hdemo_sk, cr_catalog_page_sk
  ),
  agg_returning AS (
    SELECT
      cr_item_sk,
      cr_reason_sk,
      cr_returning_hdemo_sk,
      cr_catalog_page_sk,
      SUM(cr_return_amount) AS sum_return_amount,
      AVG(cr_return_tax) AS avg_return_tax,
      COUNT(*) AS return_cnt
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_tax > 5
      AND cr_return_quantity >= 1
      AND cr_return_amount > 10
      AND cr_return_ship_cost < 50
      AND cr_store_credit BETWEEN 0 AND 20
      AND cr_fee < 5
    GROUP BY cr_item_sk, cr_reason_sk, cr_returning_hdemo_sk, cr_catalog_page_sk
  ),
  agg_hh AS (
    SELECT
      hd_demo_sk,
      SUM(CASE WHEN hd_vehicle_count > 2 THEN 1 ELSE 0 END) AS high_vehicle_cnt,
      COUNT(*) AS hd_cnt
    FROM household_demographics
    WHERE hd_dep_count <= 3
      AND hd_buy_potential IS NOT NULL
      AND hd_income_band_sk IS NOT NULL
      AND hd_vehicle_count >= 0
      AND hd_dep_count >= 0
      AND hd_buy_potential <> ''
    GROUP BY hd_demo_sk
  ),
  union_set AS (
    SELECT
      i.i_item_id AS item_id,
      r.r_reason_desc AS reason_desc,
      cp.cp_type AS page_type,
      CASE WHEN ib.ib_upper_bound > 50000 THEN 'high' ELSE 'low' END AS income_level,
      agg.sum_return_amount AS total_return,
      agg_hh.high_vehicle_cnt AS high_vehicle_cnt
    FROM agg_refunded agg
    JOIN item i ON agg.cr_item_sk = i.i_item_sk
    JOIN reason r ON agg.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON agg.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON agg.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN agg_hh ON hd.hd_demo_sk = agg_hh.hd_demo_sk
    WHERE i.i_category_id IN (1, 2, 4, 5, 10)
      AND cp.cp_type = 'monthly'
      AND r.r_reason_desc IS NOT NULL
      AND ib.ib_lower_bound >= 20000
      AND i.i_manager_id IN (19, 64, 41)
      AND i.i_container <> 'Unknown'

    UNION DISTINCT

    SELECT
      i.i_item_id AS item_id,
      r.r_reason_desc AS reason_desc,
      cp.cp_type AS page_type,
      CASE WHEN ib.ib_upper_bound > 50000 THEN 'high' ELSE 'low' END AS income_level,
      agg.sum_return_amount AS total_return,
      agg_hh.high_vehicle_cnt AS high_vehicle_cnt
    FROM agg_returning agg
    JOIN item i ON agg.cr_item_sk = i.i_item_sk
    JOIN reason r ON agg.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON agg.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON agg.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN agg_hh ON hd.hd_demo_sk = agg_hh.hd_demo_sk
    WHERE i.i_category_id IN (1, 2, 4, 5, 10)
      AND cp.cp_type = 'monthly'
      AND r.r_reason_desc IS NOT NULL
      AND ib.ib_lower_bound >= 20000
      AND i.i_manager_id IN (19, 64, 41)
      AND i.i_container <> 'Unknown'
  ),
  intersect_items AS (
    SELECT item_id FROM union_set
    INTERSECT
    SELECT i_item_id FROM item WHERE i_current_price > 25
  )
SELECT
  u.income_level,
  COUNT(DISTINCT u.item_id) AS distinct_items,
  AVG(u.total_return) AS avg_return,
  SUM(u.high_vehicle_cnt) AS total_high_vehicle
FROM union_set u
JOIN intersect_items ii ON u.item_id = ii.item_id
GROUP BY u.income_level
ORDER BY avg_return DESC
LIMIT 100

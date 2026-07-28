WITH sales_union AS (
  -- High‑income customers purchasing via AIR ship mode
  SELECT
    i.i_category AS category,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    'high_income' AS segment
  FROM catalog_sales cs
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  WHERE ib.ib_upper_bound > 100000
    AND sm.sm_type = 'AIR'
  GROUP BY i.i_category

  UNION ALL

  -- Low‑income customers purchasing via GROUND ship mode
  SELECT
    i.i_category AS category,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    'low_income' AS segment
  FROM catalog_sales cs
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  WHERE ib.ib_upper_bound <= 50000
    AND sm.sm_type = 'GROUND'
  GROUP BY i.i_category
)
SELECT
  su.category,
  su.segment,
  su.total_sales,
  (SELECT AVG(cs_ext_sales_price) FROM catalog_sales) AS avg_sales_price
FROM sales_union su
WHERE su.total_sales > (SELECT AVG(cs_ext_sales_price) FROM catalog_sales) * 10
  AND NOT EXISTS (
    SELECT 1
    FROM catalog_sales cs_ex
    JOIN ship_mode sm_ex
      ON cs_ex.cs_ship_mode_sk = sm_ex.sm_ship_mode_sk
    JOIN item i_ex
      ON cs_ex.cs_item_sk = i_ex.i_item_sk
    WHERE i_ex.i_category = su.category
      AND sm_ex.sm_type = 'EXPRESS'
  )
ORDER BY su.total_sales DESC
LIMIT 100

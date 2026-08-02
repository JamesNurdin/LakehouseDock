WITH raw AS (
  SELECT
    i.i_item_id AS i_item_id,
    i.i_brand AS i_brand,
    i.i_category AS i_category,
    sm.sm_type AS sm_type,
    CASE WHEN ib.ib_upper_bound > 150000 THEN 'High' ELSE 'Low' END AS income_group,
    cs.cs_ext_sales_price AS sales_amount,
    cr.cr_return_amount AS return_amount,
    ss.ss_ext_sales_price AS store_sales_amount,
    ws.ws_ext_sales_price AS web_sales_amount,
    wr.wr_return_amt AS web_return_amount,
    i.i_current_price AS current_price
  FROM item i
  JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE i.i_brand = 'BrandX'
    AND cs.cs_quantity > 5
    AND ss.ss_quantity > 0
  UNION DISTINCT
  SELECT
    i.i_item_id AS i_item_id,
    i.i_brand AS i_brand,
    i.i_category AS i_category,
    sm.sm_type AS sm_type,
    CASE WHEN ib.ib_upper_bound > 150000 THEN 'High' ELSE 'Low' END AS income_group,
    cs.cs_ext_sales_price AS sales_amount,
    cr.cr_return_amount AS return_amount,
    ss.ss_ext_sales_price AS store_sales_amount,
    ws.ws_ext_sales_price AS web_sales_amount,
    wr.wr_return_amt AS web_return_amount,
    i.i_current_price AS current_price
  FROM item i
  JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE i.i_brand = 'BrandY'
    AND cs.cs_quantity > 10
    AND ss.ss_quantity > 2
)
SELECT
  i_item_id,
  i_brand,
  i_category,
  sm_type,
  income_group,
  COUNT(*) AS transaction_count,
  SUM(sales_amount) AS total_sales,
  SUM(store_sales_amount) AS total_store_sales,
  SUM(web_sales_amount) AS total_web_sales,
  SUM(return_amount) AS total_catalog_returns,
  SUM(web_return_amount) AS total_web_returns,
  SUM(sales_amount + store_sales_amount + web_sales_amount - return_amount - web_return_amount) AS net_sales,
  AVG(current_price) AS avg_current_price,
  MIN(current_price) AS min_price,
  MAX(current_price) AS max_price,
  CASE WHEN SUM(sales_amount) > 10000 THEN 'TopSeller' ELSE 'Regular' END AS sales_category
FROM raw
GROUP BY
  i_item_id,
  i_brand,
  i_category,
  sm_type,
  income_group
HAVING SUM(sales_amount) > 5000
ORDER BY net_sales DESC
LIMIT 100

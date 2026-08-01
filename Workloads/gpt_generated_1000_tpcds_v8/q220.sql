WITH item_sales AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_units,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(*) AS transaction_count,
    MAX(hd.hd_income_band_sk) AS income_band_sk
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE i.i_units IN ('Bundle', 'Dozen')
    AND i.i_category = 'sports-apparel'
    AND ss.ss_coupon_amt > 100
    AND ss.ss_sold_date_sk BETWEEN 2451225 AND 2452631
    AND hd.hd_income_band_sk BETWEEN 5 AND 15
    AND EXISTS (
      SELECT 1
      FROM store_sales ss2
      WHERE ss2.ss_item_sk = i.i_item_sk
        AND ss2.ss_coupon_amt > 500
    )
  GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_category, i.i_units
)
SELECT
  isales.i_item_id,
  isales.i_product_name,
  isales.i_category,
  isales.i_units,
  isales.total_sales,
  CASE WHEN isales.total_sales > 1000 THEN 'High' ELSE 'Low' END AS sales_volume,
  isales.total_quantity,
  ROW_NUMBER() OVER (ORDER BY isales.total_sales DESC) AS global_row_num,
  ROW_NUMBER() OVER (PARTITION BY isales.i_category ORDER BY isales.total_sales DESC) AS category_row_num,
  (SELECT SUM(ss3.ss_quantity) FROM store_sales ss3 WHERE ss3.ss_item_sk = isales.i_item_sk) AS overall_quantity
FROM item_sales isales
ORDER BY isales.total_sales DESC
LIMIT 100

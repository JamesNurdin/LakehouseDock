WITH
  ws_agg AS (
    SELECT
      ws_item_sk,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_quantity) AS total_qty,
      AVG(ws_sales_price) AS avg_sales_price,
      COUNT(*) AS sales_cnt
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_ship_addr_sk IN (3078918, 4573394, 5550009, 929723)
      AND ws_sales_price > 10.00
      AND ws_ext_discount_amt < 5.00
      AND ws_order_number BETWEEN 1000000 AND 2000000
    GROUP BY ws_item_sk
  ),
  item_filtered AS (
    SELECT
      i_item_sk,
      i_category,
      i_units,
      i_current_price,
      i_brand
    FROM tpcds.item
    WHERE i_units IN ('Pound', 'Carton')
      AND i_category_id IN (1, 4, 5)
      AND i_current_price BETWEEN 5.00 AND 100.00
      AND i_brand_id IS NOT NULL
  ),
  intersect_keys AS (
    SELECT i_item_sk FROM item_filtered WHERE i_brand = 'BrandX'
    INTERSECT
    SELECT i_item_sk FROM item_filtered WHERE i_units = 'Pound'
  )
SELECT
  final.category,
  final.brand,
  SUM(final.total_sales) AS sum_sales,
  AVG(final.avg_sales_price) AS avg_price,
  COUNT(DISTINCT final.item_sk) AS distinct_items
FROM (
  SELECT
    i.i_category AS category,
    i.i_brand AS brand,
    wa.total_sales,
    wa.avg_sales_price,
    i.i_item_sk AS item_sk
  FROM ws_agg wa
  JOIN item_filtered i ON wa.ws_item_sk = i.i_item_sk
  WHERE i.i_item_sk IN (SELECT i_item_sk FROM intersect_keys)

  UNION DISTINCT

  SELECT
    i.i_category,
    i.i_brand,
    wa.total_sales,
    wa.avg_sales_price,
    i.i_item_sk
  FROM ws_agg wa
  JOIN item_filtered i ON wa.ws_item_sk = i.i_item_sk
  WHERE i.i_current_price > 50.00
) AS final
GROUP BY final.category, final.brand
ORDER BY sum_sales DESC
LIMIT 100

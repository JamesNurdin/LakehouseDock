WITH
  filtered_returns AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_market_manager,
      cc.cc_sq_ft,
      i.i_item_sk,
      i.i_brand,
      i.i_class_id,
      i.i_size,
      i.i_container,
      cr.cr_return_amount,
      cr.cr_return_tax,
      cr.cr_refunded_cash,
      cr.cr_return_amt_inc_tax,
      cr.cr_return_quantity,
      cr.cr_call_center_sk
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE i.i_class_id = 4
      AND i.i_size = 'medium'
      AND i.i_container = 'Unknown'
      AND cc.cc_market_manager = 'Mark Camp'
      AND cc.cc_sq_ft > 1000000
      AND cr.cr_refunded_cash > 200
      AND cr.cr_return_amt_inc_tax < 1000
      AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
          AND cr2.cr_refunded_cash > 300
      )
  ),
  filtered_returns2 AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_market_manager,
      cc.cc_sq_ft,
      i.i_item_sk,
      i.i_brand,
      i.i_class_id,
      i.i_size,
      i.i_container,
      cr.cr_return_amount,
      cr.cr_return_tax,
      cr.cr_refunded_cash,
      cr.cr_return_amt_inc_tax,
      cr.cr_return_quantity,
      cr.cr_call_center_sk
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE i.i_class_id = 6
      AND i.i_size = 'large'
      AND i.i_container = 'Unknown'
      AND cc.cc_market_manager = 'Gary Colburn'
      AND cc.cc_sq_ft BETWEEN 500000 AND 2000000
      AND cr.cr_refunded_cash BETWEEN 100 AND 500
      AND cr.cr_return_amt_inc_tax BETWEEN 50 AND 800
      AND EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_call_center_sk = cc.cc_call_center_sk
          AND cr3.cr_refunded_cash > 150
      )
  )
SELECT *
FROM (
  SELECT
    cc_name,
    i_brand,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(cr_return_quantity) AS min_qty,
    MAX(cr_return_quantity) AS max_qty
  FROM filtered_returns
  GROUP BY cc_name, i_brand

  UNION DISTINCT

  SELECT
    cc_name,
    i_brand,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(cr_return_quantity) AS min_qty,
    MAX(cr_return_quantity) AS max_qty
  FROM filtered_returns2
  GROUP BY cc_name, i_brand
) AS aggregated_results
ORDER BY total_return_amount DESC
LIMIT 100

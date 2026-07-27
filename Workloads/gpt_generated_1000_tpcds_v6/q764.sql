WITH
  store_ret AS (
    SELECT
      'store' AS source,
      i.i_brand AS brand,
      i.i_category AS category,
      hd.hd_vehicle_count AS vehicle_count,
      SUM(sr.sr_return_amt) AS total_return_amt,
      (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_class_id = 9) AS avg_price,
      CASE WHEN SUM(sr.sr_return_quantity) > 10 THEN 1 ELSE 0 END AS high_return_flag
    FROM store_returns sr
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_rec_end_date >= DATE '2000-01-01'
    GROUP BY i.i_brand, i.i_category, hd.hd_vehicle_count
    HAVING SUM(sr.sr_return_amt) > 1000
  ),
  web_ret AS (
    SELECT
      'web' AS source,
      i.i_brand AS brand,
      i.i_category AS category,
      hd.hd_vehicle_count AS vehicle_count,
      SUM(wr.wr_return_amt) AS total_return_amt,
      (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_class_id = 9) AS avg_price,
      CASE WHEN SUM(wr.wr_return_quantity) > 10 THEN 1 ELSE 0 END AS high_return_flag
    FROM web_returns wr
    JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
      AND wr.wr_item_sk = ws.ws_item_sk
    JOIN item i
      ON i.i_item_sk = wr.wr_item_sk
    JOIN household_demographics hd
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_rec_end_date >= DATE '2000-01-01'
    GROUP BY i.i_brand, i.i_category, hd.hd_vehicle_count
    HAVING SUM(wr.wr_return_amt) > 1000
  )
SELECT
  source,
  brand,
  category,
  vehicle_count,
  total_return_amt,
  avg_price,
  high_return_flag
FROM store_ret
UNION ALL
SELECT
  source,
  brand,
  category,
  vehicle_count,
  total_return_amt,
  avg_price,
  high_return_flag
FROM web_ret
ORDER BY total_return_amt DESC, source
LIMIT 100

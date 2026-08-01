SELECT
  cc_call_center_id,
  i_category,
  total_return_amount,
  total_sales_amount,
  return_class,
  total_web_profit
FROM (
  -- Returns side with a full outer join to keep unmatched call centers or returns
  SELECT
    cc.cc_call_center_id,
    i.i_category,
    SUM(cr.cr_return_amount) AS total_return_amount,
    CAST(NULL AS decimal(7,2)) AS total_sales_amount,
    CASE WHEN SUM(cr.cr_return_amount) > 10000 THEN 'High' ELSE 'Low' END AS return_class,
    (
      SELECT SUM(ws2.ws_net_profit)
      FROM web_sales ws2
      JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
      WHERE i2.i_category = i.i_category
    ) AS total_web_profit
  FROM call_center cc
  FULL OUTER JOIN catalog_returns cr
    ON cc.cc_call_center_sk = cr.cr_call_center_sk
  LEFT JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  WHERE i.i_units = 'Dozen'
  GROUP BY cc.cc_call_center_id, i.i_category
  HAVING SUM(cr.cr_return_amount) > 5000

  UNION

  -- Web sales side, providing a complementary view when no returns exist
  SELECT
    CAST(NULL AS varchar) AS cc_call_center_id,
    i.i_category,
    CAST(0 AS decimal(7,2)) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 20000 THEN 'High' ELSE 'Low' END AS return_class,
    (
      SELECT SUM(ws2.ws_net_profit)
      FROM web_sales ws2
      JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
      WHERE i2.i_category = i.i_category
    ) AS total_web_profit
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE i.i_units = 'Dozen'
  GROUP BY i.i_category
  HAVING SUM(ws.ws_ext_sales_price) > 10000
) AS unified
ORDER BY total_return_amount DESC, total_sales_amount DESC
LIMIT 100

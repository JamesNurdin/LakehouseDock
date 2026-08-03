WITH
  top_reasons AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_sk <= 5
  ),
  multiplier_set AS (
    SELECT n AS multiplier
    FROM (VALUES 1), (VALUES 10), (VALUES 100) AS t(n)
  ),
  base_data AS (
    SELECT
      r.r_reason_desc,
      i.i_item_desc,
      wr.wr_return_amt,
      ws.ws_net_profit,
      ws.ws_web_site_sk
    FROM web_returns wr
    JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site wsit
      ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE d.d_year = 2001
      AND wsit.web_name LIKE 'A%'
      AND i.i_brand = (SELECT i_brand FROM item WHERE i_brand_id = 5 LIMIT 1)
      AND regexp_like(i.i_item_desc, '(?i)luxury')
  )
SELECT
  tr.r_reason_desc,
  CONCAT('Reason: ', tr.r_reason_desc) AS reason_label,
  SUBSTRING(bd.i_item_desc, 1, 10) AS short_item_desc,
  REGEXP_EXTRACT(bd.i_item_desc, '(\\w+)') AS first_word,
  ms.multiplier,
  SUM(bd.wr_return_amt * ms.multiplier) AS weighted_return_amount,
  AVG(bd.ws_net_profit) AS avg_net_profit,
  COUNT(*) AS return_count
FROM top_reasons tr
JOIN base_data bd
  ON bd.r_reason_desc = tr.r_reason_desc
CROSS JOIN multiplier_set ms
GROUP BY
  tr.r_reason_desc,
  CONCAT('Reason: ', tr.r_reason_desc),
  SUBSTRING(bd.i_item_desc, 1, 10),
  REGEXP_EXTRACT(bd.i_item_desc, '(\\w+)'),
  ms.multiplier
ORDER BY weighted_return_amount DESC
LIMIT 100

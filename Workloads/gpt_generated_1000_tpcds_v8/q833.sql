WITH
  max_price AS (
    SELECT MAX(i_current_price) AS max_price
    FROM item
  ),
  eligible_items AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_current_price,
           CASE WHEN i.i_current_price = (SELECT max_price FROM max_price) THEN 'MAX' ELSE 'NORMAL' END AS price_category
    FROM item i
    WHERE i.i_current_price > 10.00
  ),
  store_agg AS (
    SELECT sr.sr_item_sk AS item_sk,
           SUM(sr.sr_return_amt) AS store_return_amt,
           COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN eligible_items ei ON sr.sr_item_sk = ei.i_item_sk
    GROUP BY sr.sr_item_sk
  ),
  web_agg AS (
    SELECT wr.wr_item_sk AS item_sk,
           SUM(wr.wr_return_amt) AS web_return_amt,
           COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN eligible_items ei ON wr.wr_item_sk = ei.i_item_sk
    GROUP BY wr.wr_item_sk
  ),
  full_returns AS (
    SELECT COALESCE(s.item_sk, w.item_sk) AS item_sk,
           s.store_return_amt,
           s.store_return_cnt,
           w.web_return_amt,
           w.web_return_cnt
    FROM store_agg s
    FULL OUTER JOIN web_agg w ON s.item_sk = w.item_sk
  ),
  union_returns AS (
    SELECT sr.sr_item_sk AS item_sk,
           sr.sr_return_amt AS return_amt,
           'store' AS src
    FROM store_returns sr
    JOIN eligible_items ei ON sr.sr_item_sk = ei.i_item_sk
    UNION ALL
    SELECT wr.wr_item_sk AS item_sk,
           wr.wr_return_amt AS return_amt,
           'web' AS src
    FROM web_returns wr
    JOIN eligible_items ei ON wr.wr_item_sk = ei.i_item_sk
  ),
  agg_union AS (
    SELECT item_sk,
           SUM(return_amt) AS total_return_amt,
           COUNT(*) AS total_return_cnt
    FROM union_returns
    GROUP BY item_sk
  ),
  final AS (
    SELECT ei.i_item_sk,
           ei.i_product_name,
           ei.i_current_price,
           ei.price_category,
           fr.store_return_amt,
           fr.store_return_cnt,
           fr.web_return_amt,
           fr.web_return_cnt,
           au.total_return_amt,
           au.total_return_cnt,
           CASE WHEN au.total_return_amt > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
           lt.ten_percent_return
    FROM eligible_items ei
    LEFT JOIN full_returns fr ON ei.i_item_sk = fr.item_sk
    LEFT JOIN agg_union au ON ei.i_item_sk = au.item_sk
    LEFT JOIN LATERAL (
      SELECT COALESCE(au.total_return_amt, 0) * 0.1 AS ten_percent_return
    ) lt ON TRUE
    WHERE ei.i_item_sk NOT IN (
      SELECT p_item_sk FROM promotion WHERE p_discount_active = 'Y'
    )
  )
SELECT i_item_sk,
       i_product_name,
       i_current_price,
       price_category,
       store_return_amt,
       store_return_cnt,
       web_return_amt,
       web_return_cnt,
       total_return_amt,
       total_return_cnt,
       return_level,
       ten_percent_return
FROM final
ORDER BY total_return_amt DESC
LIMIT 100

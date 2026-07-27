WITH returned_items AS (
  SELECT
    i.i_item_sk,
    i.i_category,
    i.i_item_desc,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM store_returns sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE regexp_like(r.r_reason_desc, '(?i)damaged')
    AND i.i_item_desc LIKE 'A%'
  GROUP BY i.i_item_sk, i.i_category, i.i_item_desc
)
SELECT
  ri.i_category,
  ri.i_item_desc,
  regexp_extract(ri.i_item_desc, '^([^ ]+)', 1) AS first_word,
  concat(ri.i_category, ':', regexp_extract(ri.i_item_desc, '^([^ ]+)', 1)) AS cat_firstword,
  ri.total_net_loss,
  ri.return_cnt,
  (
    SELECT COUNT(*)
    FROM store_sales ss
    WHERE ss.ss_item_sk = ri.i_item_sk
      AND ss.ss_net_profit > 1000
  ) AS high_profit_sales_cnt
FROM returned_items ri
WHERE ri.total_net_loss > (
  SELECT AVG(total_net_loss)
  FROM returned_items
)
ORDER BY ri.total_net_loss DESC
LIMIT 100

/* goal: Compare average net loss for store and catalog returns by item category for the year 2001, include total web sales per item, keep only categories with more than 10 returns, and present the top results after deduplication */
SELECT
  u.item_category,
  u.return_year,
  u.avg_net_loss,
  u.return_cnt,
  u.total_web_sales
FROM (
  SELECT
    i.i_category               AS item_category,
    d.d_year                   AS return_year,
    AVG(sr.sr_net_loss)       AS avg_net_loss,
    COUNT(*)                   AS return_cnt,
    (SELECT SUM(ws.ws_ext_sales_price)
       FROM web_sales ws
      WHERE ws.ws_item_sk = i.i_item_sk) AS total_web_sales
  FROM store_returns sr TABLESAMPLE BERNOULLI (10)
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND EXISTS (
          SELECT 1
            FROM promotion p
           WHERE p.p_item_sk = i.i_item_sk
             AND p.p_discount_active = 'Y'
        )
  GROUP BY i.i_category, d.d_year, i.i_item_sk
  HAVING COUNT(*) > 10

  UNION

  SELECT
    i.i_category               AS item_category,
    d.d_year                   AS return_year,
    AVG(cr.cr_net_loss)       AS avg_net_loss,
    COUNT(*)                   AS return_cnt,
    (SELECT SUM(ws.ws_ext_sales_price)
       FROM web_sales ws
      WHERE ws.ws_item_sk = i.i_item_sk) AS total_web_sales
  FROM catalog_returns cr TABLESAMPLE BERNOULLI (10)
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND EXISTS (
          SELECT 1
            FROM promotion p
           WHERE p.p_item_sk = i.i_item_sk
             AND p.p_discount_active = 'Y'
        )
  GROUP BY i.i_category, d.d_year, i.i_item_sk
  HAVING COUNT(*) > 10
) u
ORDER BY u.avg_net_loss DESC, u.item_category ASC
OFFSET 10
LIMIT 100

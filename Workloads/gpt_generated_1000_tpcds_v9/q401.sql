SELECT i.i_brand,
       i.i_category,
       SUM(cr.cr_refunded_cash) AS total_refunded_cash,
       COUNT(*) AS return_cnt
FROM catalog_returns cr
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
WHERE cr.cr_refunded_cash > 500
  AND i.i_class_id = 13
GROUP BY i.i_brand, i.i_category
ORDER BY total_refunded_cash DESC

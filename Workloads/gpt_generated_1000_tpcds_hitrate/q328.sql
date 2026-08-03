SELECT i.i_category,
       SUM(cr.cr_return_amount) AS total_return_amount
FROM catalog_returns cr
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
WHERE i.i_category_id = 3
  AND cr.cr_return_amount > 100.00
GROUP BY i.i_category
ORDER BY total_return_amount DESC

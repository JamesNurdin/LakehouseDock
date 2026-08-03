WITH sampled_items AS (
      SELECT i_item_sk, i_color, i_product_name
      FROM item TABLESAMPLE BERNOULLI (10)
      WHERE regexp_like(i_color, '^s.*')
    ),
    item_returns AS (
      SELECT wr_item_sk, SUM(wr_return_amt) AS total_return_amt
      FROM web_returns
      WHERE wr_return_amt > 0
      GROUP BY wr_item_sk
    ),
    reason_filtered AS (
      SELECT r_reason_sk, r_reason_desc
      FROM reason
      WHERE r_reason_desc LIKE '%damaged%'
    ),
    intersect_keys AS (
      SELECT i_item_sk FROM sampled_items
      INTERSECT
      SELECT wr_item_sk FROM web_returns WHERE wr_fee > 20
    ),
    except_keys AS (
      SELECT i_item_sk FROM item
      EXCEPT
      SELECT wr_item_sk FROM web_returns
    ),
    item_reason AS (
      SELECT wr_item_sk, MAX(wr_reason_sk) AS reason_sk
      FROM web_returns
      GROUP BY wr_item_sk
    )
SELECT i.i_item_sk,
       i.i_product_name,
       i.i_color,
       r.r_reason_desc,
       ir.total_return_amt,
       (SELECT SUM(wr_fee) FROM web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk) AS total_fee_per_item,
       (SELECT AVG(wr_fee) FROM web_returns) AS avg_fee_all
FROM item i
JOIN item_reason irn ON irn.wr_item_sk = i.i_item_sk
JOIN reason_filtered r ON r.r_reason_sk = irn.reason_sk
JOIN item_returns ir ON ir.wr_item_sk = i.i_item_sk
WHERE i.i_item_sk IN (SELECT i_item_sk FROM intersect_keys)
  AND i.i_item_sk NOT IN (SELECT i_item_sk FROM except_keys)
  AND i.i_product_name LIKE CONCAT('%', SUBSTRING(i.i_color, 1, 3), '%')
  AND i.i_product_name LIKE '%Box%'
  AND i.i_item_sk > (SELECT MIN(wr_item_sk) FROM web_returns)
ORDER BY ir.total_return_amt DESC
LIMIT 100

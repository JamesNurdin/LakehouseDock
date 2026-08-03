WITH
  filtered_items AS (
    SELECT
      i_item_sk,
      i_item_id,
      i_product_name,
      i_brand,
      i_color,
      CONCAT(i_brand, ' ', i_product_name) AS brand_product,
      CASE WHEN regexp_like(i_product_name, '[A-Z]{2}[0-9]{3}') THEN 1 ELSE 0 END AS has_code
    FROM item
    WHERE i_product_name LIKE '%Pro%' OR i_color LIKE 'Red%'
  ),
  promo_items AS (
    SELECT p_item_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
      AND regexp_like(p_promo_name, '^Summer')
  ),
  intersect_items AS (
    SELECT i_item_sk FROM filtered_items
    INTERSECT
    SELECT p_item_sk FROM promo_items
  ),
  return_facts AS (
    SELECT
      sr_item_sk,
      SUM(sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt,
      SUM(sr_fee) AS total_fee
    FROM store_returns
    WHERE sr_fee > 20
    GROUP BY sr_item_sk
  ),
  reason_filtered AS (
    SELECT sr_item_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%Did not%'
  ),
  except_items AS (
    SELECT sr_item_sk FROM return_facts
    EXCEPT
    SELECT sr_item_sk FROM reason_filtered
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_brand,
  i.i_color,
  fi.brand_product,
  rf.total_return_amt,
  rf.return_cnt,
  rf.total_fee
FROM intersect_items ii
JOIN filtered_items fi ON ii.i_item_sk = fi.i_item_sk
JOIN item i ON i.i_item_sk = fi.i_item_sk
JOIN return_facts rf ON rf.sr_item_sk = i.i_item_sk
JOIN except_items ei ON ei.sr_item_sk = i.i_item_sk
WHERE fi.has_code = 1
  AND rf.total_return_amt > (
        SELECT AVG(total_return_amt) FROM return_facts
      )
ORDER BY rf.total_return_amt DESC
OFFSET 0 LIMIT 100

SELECT
  'training' AS split,
  pr_review_id,
  CASE pr_rating
    WHEN 1 THEN 'NEG'
    WHEN 2 THEN 'NEG'
    WHEN 3 THEN 'NEU'
    WHEN 4 THEN 'POS'
    WHEN 5 THEN 'POS'
  END AS pr_r_rating,
  pr_content
FROM iceberg.bigbenchv2_sf1.product_reviews
WHERE mod(pr_review_id, 5) IN (1, 2, 3)

UNION ALL

SELECT
  'testing' AS split,
  pr_review_id,
  CASE pr_rating
    WHEN 1 THEN 'NEG'
    WHEN 2 THEN 'NEG'
    WHEN 3 THEN 'NEU'
    WHEN 4 THEN 'POS'
    WHEN 5 THEN 'POS'
  END AS pr_r_rating,
  pr_content
FROM iceberg.bigbenchv2_sf1.product_reviews
WHERE mod(pr_review_id, 5) IN (0, 4)
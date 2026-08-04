WITH sales AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    SUM(cs.cs_ext_sales_price) AS total_amount,
    'sale' AS txn_type,
    latest_promo.promo_name
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  CROSS JOIN LATERAL (
    SELECT p.p_promo_name AS promo_name
    FROM promotion p
    WHERE p.p_item_sk = i.i_item_sk
    ORDER BY p.p_start_date_sk DESC
    LIMIT 1
  ) AS latest_promo
  WHERE d.d_year = 2020
    AND EXISTS (
      SELECT 1 FROM promotion p2
      WHERE p2.p_item_sk = i.i_item_sk
        AND p2.p_start_date_sk = d.d_date_sk
    )
  GROUP BY i.i_item_id, i.i_product_name, latest_promo.promo_name
),
returns AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_amount,
    'return' AS txn_type,
    latest_promo.promo_name
  FROM catalog_returns cr
  FULL OUTER JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON COALESCE(cr.cr_item_sk, cs.cs_item_sk) = i.i_item_sk
  LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  CROSS JOIN LATERAL (
    SELECT p.p_promo_name AS promo_name
    FROM promotion p
    WHERE p.p_item_sk = i.i_item_sk
    ORDER BY p.p_start_date_sk DESC
    LIMIT 1
  ) AS latest_promo
  WHERE d.d_year = 2020
    AND EXISTS (
      SELECT 1 FROM promotion p2
      WHERE p2.p_item_sk = i.i_item_sk
        AND p2.p_start_date_sk = d.d_date_sk
    )
  GROUP BY i.i_item_id, i.i_product_name, latest_promo.promo_name
)
SELECT
  u.i_item_id,
  u.i_product_name,
  u.total_amount,
  u.txn_type,
  u.promo_name,
  (SELECT COUNT(*) FROM customer c WHERE c.c_birth_year = 1980) AS customers_1980
FROM (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
) AS u
ORDER BY u.total_amount DESC
LIMIT 100

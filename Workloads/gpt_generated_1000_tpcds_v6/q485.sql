WITH catalog_agg AS (
  SELECT
    'catalog' AS source,
    cp.cp_department AS category,
    SUM(cs.cs_net_paid) AS total_amount,
    COUNT(DISTINCT cs.cs_order_number) AS transaction_count
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_carrier = 'UPS'
    AND p.p_discount_active = 'Y'
  GROUP BY cp.cp_department
),
web_agg AS (
  SELECT
    'web' AS source,
    wp.wp_type AS category,
    SUM(wr.wr_return_amt) AS total_amount,
    COUNT(DISTINCT wr.wr_order_number) AS transaction_count
  FROM web_returns wr
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_image_count > 2
    AND EXISTS (
      SELECT 1
      FROM customer_demographics cd
      WHERE cd.cd_demo_sk = wr.wr_refunded_cdemo_sk
        AND cd.cd_purchase_estimate > 8000
    )
  GROUP BY wp.wp_type
)
SELECT source, category, total_amount, transaction_count
FROM catalog_agg
UNION ALL
SELECT source, category, total_amount, transaction_count
FROM web_agg
ORDER BY total_amount DESC
LIMIT 100

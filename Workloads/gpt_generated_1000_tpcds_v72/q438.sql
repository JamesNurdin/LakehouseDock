WITH store_sales_agg AS (
  SELECT
    'store_sales' AS source_type,
    s.s_store_id AS entity_id,
    s.s_store_name AS entity_name,
    SUM(ss.ss_net_paid) AS total_amount
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_gender = 'M'
    AND cd.cd_purchase_estimate > 4000
  GROUP BY s.s_store_id, s.s_store_name
),
web_returns_agg AS (
  SELECT
    'web_returns' AS source_type,
    wp.wp_web_page_id AS entity_id,
    wp.wp_url AS entity_name,
    SUM(wr.wr_net_loss) AS total_amount
  FROM web_returns wr
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN customer_demographics cd
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_gender = 'M'
    AND cd.cd_purchase_estimate > 4000
  GROUP BY wp.wp_web_page_id, wp.wp_url
)
SELECT source_type, entity_id, entity_name, total_amount
FROM store_sales_agg
UNION ALL
SELECT source_type, entity_id, entity_name, total_amount
FROM web_returns_agg
ORDER BY total_amount DESC
LIMIT 100

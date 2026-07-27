WITH store_agg AS (
  SELECT
    i.i_category AS category,
    cd.cd_education_status AS education_status,
    SUM(ss.ss_net_paid) AS total_sales,
    CASE WHEN SUM(ss.ss_quantity) > 100 THEN 'High' ELSE 'Low' END AS sales_volume_flag,
    'store' AS source,
    (SELECT COUNT(DISTINCT ss2.ss_customer_sk)
       FROM store_sales ss2
       WHERE ss2.ss_item_sk = ss.ss_item_sk) AS distinct_customers
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE i.i_category_id = 5
    AND cd.cd_marital_status = 'M'
  GROUP BY i.i_category, cd.cd_education_status, ss.ss_item_sk
),
web_agg AS (
  SELECT
    i.i_category AS category,
    cd.cd_education_status AS education_status,
    SUM(ws.ws_net_paid) AS total_sales,
    CASE WHEN SUM(ws.ws_quantity) > 100 THEN 'High' ELSE 'Low' END AS sales_volume_flag,
    'web' AS source,
    (SELECT COUNT(DISTINCT ws2.ws_bill_customer_sk)
       FROM web_sales ws2
       WHERE ws2.ws_item_sk = ws.ws_item_sk) AS distinct_customers
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
      AND wp.wp_type = 'article'
  )
    AND i.i_category_id = 5
    AND cd.cd_marital_status = 'M'
  GROUP BY i.i_category, cd.cd_education_status, ws.ws_item_sk
)
SELECT *
FROM (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
) combined
ORDER BY total_sales DESC
LIMIT 100

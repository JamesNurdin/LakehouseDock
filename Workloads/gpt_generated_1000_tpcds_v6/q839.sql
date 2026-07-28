WITH catalog_agg AS (
  SELECT
    i.i_item_id AS item_id,
    d.d_year AS year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt,
    CASE
      WHEN regexp_like(i.i_item_desc, '(?i)SSD|HDD') THEN 'Storage'
      ELSE 'Other'
    END AS category_flag
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE i.i_item_desc LIKE '%Blue%'
    AND d.d_year BETWEEN 2001 AND 2002
  GROUP BY i.i_item_id,
           d.d_year,
           CASE
             WHEN regexp_like(i.i_item_desc, '(?i)SSD|HDD') THEN 'Storage'
             ELSE 'Other'
           END
),
web_agg AS (
  SELECT
    i.i_item_id AS item_id,
    d.d_year AS year,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt,
    CASE
      WHEN regexp_like(i.i_item_desc, '(?i)SSD|HDD') THEN 'Storage'
      ELSE 'Other'
    END AS category_flag
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE i.i_item_desc LIKE '%Blue%'
    AND d.d_year BETWEEN 2001 AND 2002
  GROUP BY i.i_item_id,
           d.d_year,
           CASE
             WHEN regexp_like(i.i_item_desc, '(?i)SSD|HDD') THEN 'Storage'
             ELSE 'Other'
           END
)
SELECT
  concat(combined.sales_channel, '_', cast(combined.year AS varchar)) AS channel_year,
  combined.item_id,
  combined.total_sales,
  combined.order_cnt,
  combined.category_flag
FROM (
  SELECT
    'catalog' AS sales_channel,
    ca.item_id,
    ca.year,
    ca.total_sales,
    ca.order_cnt,
    ca.category_flag
  FROM catalog_agg ca
  UNION ALL
  SELECT
    'web' AS sales_channel,
    wa.item_id,
    wa.year,
    wa.total_sales,
    wa.order_cnt,
    wa.category_flag
  FROM web_agg wa
) AS combined
WHERE combined.total_sales > 100000
ORDER BY combined.sales_channel, combined.total_sales DESC

WITH store_sales_agg AS (
  SELECT
    s.s_store_name AS channel_name,
    d.d_date AS sales_date,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
    AND EXISTS (
      SELECT 1
      FROM store_returns sr
      JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
      WHERE sr.sr_store_sk = ss.ss_store_sk
        AND dr.d_year = 2001
        AND dr.d_date = d.d_date
    )
  GROUP BY s.s_store_name, d.d_date
),
catalog_sales_agg AS (
  SELECT
    cc.cc_name AS channel_name,
    d.d_date AS sales_date,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
  GROUP BY cc.cc_name, d.d_date
)
SELECT *
FROM (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM catalog_sales_agg
) AS combined
ORDER BY total_profit DESC, channel_name
LIMIT 100

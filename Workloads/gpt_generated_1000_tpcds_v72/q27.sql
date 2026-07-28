/*
Goal: Compare quarterly net profit from store sales with quarterly net loss from catalog returns for the year 2001, categorizing the amounts and showing the overall average profit for reference.
*/
WITH
  store_sales_agg AS (
    SELECT
      s.s_store_sk      AS entity_key,
      s.s_store_name    AS entity_name,
      d.d_quarter_seq   AS quarter,
      SUM(ss.ss_net_profit) AS amount,
      'store_sales'     AS source
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_sk, s.s_store_name, d.d_quarter_seq
  ),
  catalog_returns_agg AS (
    SELECT
      cc.cc_call_center_sk AS entity_key,
      cc.cc_name           AS entity_name,
      d.d_quarter_seq      AS quarter,
      SUM(cr.cr_net_loss)  AS amount,
      'catalog_returns'    AS source
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cc.cc_call_center_sk, cc.cc_name, d.d_quarter_seq
  ),
  overall_avg AS (
    SELECT AVG(qtr_amount) AS avg_amount
    FROM (
      SELECT SUM(ss.ss_net_profit) AS qtr_amount
      FROM store_sales ss
      JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
      WHERE d.d_year = 2001
      GROUP BY d.d_quarter_seq
    ) q
  )
SELECT
  combined.entity_key,
  combined.entity_name,
  combined.quarter,
  combined.amount,
  CASE WHEN combined.amount < 0 THEN 'Loss' ELSE 'Profit' END AS amount_category,
  combined.source,
  (SELECT avg_amount FROM overall_avg) AS overall_avg_amount
FROM (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM catalog_returns_agg
) combined
WHERE EXISTS (
  SELECT 1
  FROM store_sales ss2
  JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
  WHERE d2.d_year = 2001
    AND ss2.ss_quantity > 100
)
ORDER BY combined.amount DESC
LIMIT 100

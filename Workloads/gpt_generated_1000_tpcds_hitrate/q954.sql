WITH
  store_profit AS (
    SELECT
      s.s_store_id,
      i.i_category,
      SUM(ss.ss_net_profit) AS total_profit,
      CASE WHEN SUM(ss.ss_net_profit) > 5000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM store_sales ss
    RIGHT OUTER JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_state = 'CA'
      AND (hd.hd_income_band_sk = 5 OR hd.hd_income_band_sk IS NULL)
    GROUP BY s.s_store_id, i.i_category
    HAVING SUM(ss.ss_net_profit) IS NOT NULL
       AND SUM(ss.ss_net_profit) > 1000
  ),
  store_view AS (
    SELECT
      s_store_id AS store_id,
      i_category AS category,
      total_profit AS profit_amount,
      profit_level,
      LAG(total_profit) OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS prev_profit
    FROM store_profit
  ),
  catalog_sales_agg AS (
    SELECT
      cp.cp_department,
      cs.cs_order_number,
      SUM(cs.cs_net_profit) AS cat_total_profit,
      CASE WHEN SUM(cs.cs_quantity) > 5 THEN 'Bulk' ELSE 'Single' END AS order_type
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cp.cp_department = 'Electronics'
      AND cc.cc_state = 'CA'
      AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
      )
    GROUP BY cp.cp_department, cs.cs_order_number
    HAVING SUM(cs.cs_net_profit) > 0
  ),
  catalog_view AS (
    SELECT
      CAST(NULL AS varchar) AS store_id,
      cp_department AS category,
      cat_total_profit AS profit_amount,
      order_type AS profit_level,
      SUM(cat_total_profit) OVER (
        PARTITION BY cp_department
        ORDER BY cat_total_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS prev_profit
    FROM catalog_sales_agg
  )
SELECT *
FROM store_view
UNION ALL
SELECT *
FROM catalog_view
ORDER BY profit_amount DESC
LIMIT 100

WITH
 cat_sales AS (
   SELECT
     cs.cs_item_sk,
     cs.cs_sold_date_sk AS sold_date_sk,
     SUM(cs.cs_net_paid) AS cat_net_paid,
     SUM(cs.cs_net_profit) AS cat_net_profit,
     COUNT(*) AS cat_transactions,
     MAX(cs.cs_sold_time_sk) AS cat_last_time_sk
   FROM catalog_sales cs
   LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
 ),
 store_sales_agg AS (
   SELECT
     ss.ss_item_sk,
     ss.ss_sold_date_sk AS sold_date_sk,
     SUM(ss.ss_net_paid) AS store_net_paid,
     SUM(ss.ss_net_profit) AS store_net_profit,
     COUNT(*) AS store_transactions,
     MAX(ss.ss_sold_time_sk) AS store_last_time_sk
   FROM store_sales ss
   LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year IS NOT NULL
   GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk
 ),
 web_sales_agg AS (
   SELECT
     ws.ws_item_sk,
     ws.ws_sold_date_sk AS sold_date_sk,
     SUM(ws.ws_net_paid) AS web_net_paid,
     SUM(ws.ws_net_profit) AS web_net_profit,
     COUNT(*) AS web_transactions,
     MAX(ws.ws_sold_time_sk) AS web_last_time_sk
   FROM web_sales ws
   LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
 ),
 combined_sales AS (
   SELECT
     COALESCE(cat.cs_item_sk, st.ss_item_sk, wb.ws_item_sk) AS item_sk,
     COALESCE(cat.sold_date_sk, st.sold_date_sk, wb.sold_date_sk) AS sold_date_sk,
     cat.cat_net_paid,
     st.store_net_paid,
     wb.web_net_paid,
     cat.cat_net_profit,
     st.store_net_profit,
     wb.web_net_profit,
     cat.cat_transactions,
     st.store_transactions,
     wb.web_transactions,
     cat.cat_last_time_sk,
     st.store_last_time_sk,
     wb.web_last_time_sk
   FROM cat_sales cat
   FULL OUTER JOIN store_sales_agg st
     ON cat.cs_item_sk = st.ss_item_sk
        AND cat.sold_date_sk = st.sold_date_sk
   FULL OUTER JOIN web_sales_agg wb
     ON COALESCE(cat.cs_item_sk, st.ss_item_sk) = wb.ws_item_sk
        AND COALESCE(cat.sold_date_sk, st.sold_date_sk) = wb.sold_date_sk
 ),
 latest_returns AS (
   SELECT
     cr.cr_item_sk AS item_sk,
     cr.cr_returned_date_sk AS returned_date_sk,
     SUM(cr.cr_return_amount) AS total_return_amount,
     MAX(cr.cr_returned_time_sk) AS latest_return_time_sk
   FROM catalog_returns cr
   GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk
 ),
 enriched_sales AS (
   SELECT
     cs.item_sk,
     cs.sold_date_sk,
     cs.cat_net_paid,
     cs.store_net_paid,
     cs.web_net_paid,
     cs.cat_net_profit,
     cs.store_net_profit,
     cs.web_net_profit,
     cs.cat_transactions,
     cs.store_transactions,
     cs.web_transactions,
     cs.cat_last_time_sk,
     cs.store_last_time_sk,
     cs.web_last_time_sk,
     lr.total_return_amount
   FROM combined_sales cs
   LEFT JOIN latest_returns lr
     ON cs.item_sk = lr.item_sk
        AND cs.sold_date_sk = lr.returned_date_sk
 ),
 item_customer_stats AS (
   SELECT
     i.i_item_sk,
     i.i_product_name,
     i.i_brand,
     i.i_category,
     i.i_color,
     i.i_size,
     i.i_formulation,
     i.i_manager_id,
     (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = i.i_item_sk AND ss.ss_quantity > 5) AS high_qty_store_sales_cnt,
     (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_item_sk = i.i_item_sk AND cs.cs_quantity > 5) AS high_qty_catalog_sales_cnt,
     (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_item_sk = i.i_item_sk AND ws.ws_quantity > 5) AS high_qty_web_sales_cnt,
     (SELECT MAX(c.c_last_review_date) FROM customer c JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk WHERE ss.ss_item_sk = i.i_item_sk) AS latest_customer_review_date
   FROM item i
 ),
 final AS (
   SELECT
     e.item_sk,
     i.i_product_name,
     COALESCE(i.i_brand, 'UNKNOWN') AS brand,
     COALESCE(i.i_category, 'OTHER') AS category,
     e.sold_date_sk,
     d.d_date,
     CASE WHEN e.cat_net_paid IS NULL AND e.store_net_paid IS NULL AND e.web_net_paid IS NULL THEN 0 ELSE COALESCE(e.cat_net_paid,0)+COALESCE(e.store_net_paid,0)+COALESCE(e.web_net_paid,0) END AS total_net_paid,
     CASE WHEN e.total_return_amount IS NOT NULL THEN e.total_return_amount ELSE 0 END AS total_return_amount,
     (COALESCE(e.cat_net_profit,0)+COALESCE(e.store_net_profit,0)+COALESCE(e.web_net_profit,0)) - COALESCE(e.total_return_amount,0) AS net_profit_after_returns,
     (e.cat_transactions + e.store_transactions + e.web_transactions) AS total_transactions,
     GREATEST(
       COALESCE(e.cat_last_time_sk,0),
       COALESCE(e.store_last_time_sk,0),
       COALESCE(e.web_last_time_sk,0)
     ) AS latest_time_sk,
     CASE WHEN (e.cat_transactions + e.store_transactions + e.web_transactions) = 0 THEN NULL
          ELSE (COALESCE(e.cat_net_paid,0)+COALESCE(e.store_net_paid,0)+COALESCE(e.web_net_paid,0))/
               NULLIF((e.cat_transactions + e.store_transactions + e.web_transactions),0) END AS avg_net_paid_per_tx,
     CONCAT_WS('|', i.i_color, i.i_size, i.i_formulation) AS attr_concat,
     NULLIF(CAST(i.i_manager_id AS varchar), '') AS mgr_id_str,
     PERCENT_RANK() OVER (PARTITION BY i.i_category ORDER BY (COALESCE(e.cat_net_paid,0)+COALESCE(e.store_net_paid,0)+COALESCE(e.web_net_paid,0)) DESC) AS category_sales_percentile,
     (SELECT COUNT(DISTINCT ss.ss_customer_sk) FROM store_sales ss
       WHERE ss.ss_item_sk = e.item_sk
         AND EXISTS (SELECT 1 FROM customer c WHERE c.c_customer_sk = ss.ss_customer_sk AND c.c_preferred_cust_flag = 'Y')) AS pref_y_customer_cnt,
     CASE WHEN i.i_brand IS NOT DISTINCT FROM 'Brand#12' THEN 1 ELSE 0 END AS is_brand_12_flag,
     ic.high_qty_store_sales_cnt,
     ic.high_qty_catalog_sales_cnt,
     ic.high_qty_web_sales_cnt,
     ic.latest_customer_review_date,
     cc.cc_name AS call_center_name
   FROM enriched_sales e
   JOIN item i ON e.item_sk = i.i_item_sk
   LEFT JOIN item_customer_stats ic ON i.i_item_sk = ic.i_item_sk
   LEFT JOIN date_dim d ON e.sold_date_sk = d.d_date_sk
   LEFT JOIN call_center cc
     ON substring(cc.cc_zip,1,2) = substring(i.i_item_id,1,2)
   WHERE (i.i_category = 'Sports' OR i.i_category = 'Books')
     AND (i.i_brand IS NOT NULL AND i.i_brand <> '')
 )
SELECT *
FROM final
WHERE net_profit_after_returns > 0
  AND (category_sales_percentile < 0.5 OR category_sales_percentile IS NULL)
  AND (pref_y_customer_cnt IS NULL OR pref_y_customer_cnt > 0)
UNION ALL
SELECT
   NULL AS item_sk,
   'TOTAL' AS i_product_name,
   NULL AS brand,
   NULL AS category,
   NULL AS sold_date_sk,
   NULL AS d_date,
   SUM(total_net_paid) AS total_net_paid,
   SUM(total_return_amount) AS total_return_amount,
   SUM(net_profit_after_returns) AS net_profit_after_returns,
   SUM(total_transactions) AS total_transactions,
   NULL AS latest_time_sk,
   NULL AS avg_net_paid_per_tx,
   NULL AS attr_concat,
   NULL AS mgr_id_str,
   NULL AS category_sales_percentile,
   NULL AS pref_y_customer_cnt,
   NULL AS is_brand_12_flag,
   SUM(high_qty_store_sales_cnt) AS high_qty_store_sales_cnt,
   SUM(high_qty_catalog_sales_cnt) AS high_qty_catalog_sales_cnt,
   SUM(high_qty_web_sales_cnt) AS high_qty_web_sales_cnt,
   MAX(latest_customer_review_date) AS latest_customer_review_date,
   NULL AS call_center_name
FROM final
WHERE net_profit_after_returns > 0
  AND (category_sales_percentile < 0.5 OR category_sales_percentile IS NULL)
  AND (pref_y_customer_cnt IS NULL OR pref_y_customer_cnt > 0)

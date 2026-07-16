WITH
store_sales_cte AS (
 SELECT
   ss_sold_date_sk AS date_sk,
   ss_store_sk AS location_sk,
   'store' AS src,
   ss_item_sk AS item_sk,
   ss_quantity AS qty,
   ss_net_profit AS profit,
   ss_net_paid_inc_tax AS revenue,
   ss_ext_discount_amt AS discount_amt
 FROM store_sales
),
catalog_sales_cte AS (
 SELECT
   cs_sold_date_sk AS date_sk,
   cs_call_center_sk AS location_sk,
   'catalog' AS src,
   cs_item_sk AS item_sk,
   cs_quantity AS qty,
   cs_net_profit AS profit,
   cs_net_paid_inc_tax AS revenue,
   cs_ext_discount_amt AS discount_amt
 FROM catalog_sales
),
web_sales_cte AS (
 SELECT
   ws_sold_date_sk AS date_sk,
   ws_web_page_sk AS location_sk,
   'web' AS src,
   ws_item_sk AS item_sk,
   ws_quantity AS qty,
   ws_net_profit AS profit,
   ws_net_paid_inc_tax AS revenue,
   ws_ext_discount_amt AS discount_amt
 FROM web_sales
),
sales_union AS (
 SELECT * FROM store_sales_cte
 UNION ALL
 SELECT * FROM catalog_sales_cte
 UNION ALL
 SELECT * FROM web_sales_cte
),
returns_data AS (
 SELECT
   sr_returned_date_sk AS date_sk,
   sr_item_sk AS item_sk,
   sr_return_quantity AS qty,
   sr_net_loss AS loss
 FROM store_returns
 UNION ALL
 SELECT
   cr_returned_date_sk,
   cr_item_sk,
   cr_return_quantity,
   cr_net_loss
 FROM catalog_returns
 UNION ALL
 SELECT
   wr_returned_date_sk,
   wr_item_sk,
   wr_return_quantity,
   wr_net_loss
 FROM web_returns
),
sales_with_returns AS (
 SELECT
   su.date_sk,
   su.location_sk,
   su.src,
   su.item_sk,
   su.qty,
   su.profit,
   su.revenue,
   su.discount_amt,
   COALESCE(rd.loss, 0) AS loss,
   COALESCE(rd.qty, 0) AS return_qty
 FROM sales_union su
 LEFT JOIN returns_data rd
   ON su.date_sk = rd.date_sk AND su.item_sk = rd.item_sk
),
location_names AS (
 SELECT
   swr.*,
   CASE
     WHEN swr.src = 'store' THEN COALESCE(s.s_store_name, 'UNKNOWN_STORE')
     WHEN swr.src = 'catalog' THEN COALESCE(cc.cc_name, 'UNKNOWN_CC')
     ELSE COALESCE(wp.wp_url, 'UNKNOWN_WEB')
   END AS location_name,
   ROW_NUMBER() OVER (PARTITION BY swr.location_sk ORDER BY swr.date_sk) AS seq_per_loc,
   SUM(swr.profit - swr.loss) OVER (PARTITION BY swr.location_sk ORDER BY swr.date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_profit
 FROM sales_with_returns swr
 LEFT JOIN store s ON swr.location_sk = s.s_store_sk AND swr.src = 'store'
 LEFT JOIN call_center cc ON swr.location_sk = cc.cc_call_center_sk AND swr.src = 'catalog'
 LEFT JOIN web_page wp ON swr.location_sk = wp.wp_web_page_sk AND swr.src = 'web'
),
final_calc AS (
 SELECT
   ln.*,
   (SELECT d_year FROM date_dim d WHERE d.d_date_sk = ln.date_sk) AS sale_year,
   CASE
     WHEN (ln.qty - ln.return_qty) = 0 THEN NULL
     ELSE (ln.profit - ln.loss) / NULLIF(ln.qty - ln.return_qty, 0)
   END AS profit_per_unit,
   CONCAT(COALESCE(ln.location_name, 'NULL'), ' - ', CAST(ln.date_sk AS varchar)) AS composite_key,
   CASE
     WHEN ln.discount_amt IS NULL THEN 'NO_DISCOUNT'
     WHEN ln.discount_amt = 0 THEN 'ZERO_DISCOUNT'
     ELSE 'DISCOUNTED'
   END AS discount_flag,
   ROW_NUMBER() OVER (PARTITION BY ln.location_sk ORDER BY (ln.profit - ln.loss) DESC) AS profit_rank,
   CASE WHEN ln.seq_per_loc % 2 = 0 THEN 'EVEN_SEQ' ELSE 'ODD_SEQ' END AS seq_parity,
   COALESCE(NULLIF((ln.profit - ln.loss) / NULLIF(ln.qty - ln.return_qty, 0), 0), -9999) AS profit_per_unit_adj
 FROM location_names ln
),
filtered AS (
 SELECT *
 FROM final_calc
 WHERE profit_rank <= 10
   AND discount_flag = 'DISCOUNTED'
   AND profit_per_unit_adj IS NOT NULL
   AND NOT (location_name = '' AND location_name IS NULL)
   AND seq_parity IS NOT NULL
   AND sale_year IS NOT NULL
   AND sale_year % 2 = 0
),
ranked_set AS (
 SELECT location_name, src, profit, loss, profit_rank FROM filtered
 UNION ALL
 SELECT location_name, src, profit, loss, profit_rank FROM filtered WHERE src = 'store' AND profit_rank = 1
),
final_result AS (
 SELECT *
 FROM ranked_set
 EXCEPT
 SELECT *
 FROM ranked_set
 WHERE profit <= 0
)
SELECT *
FROM final_result
ORDER BY profit_rank, location_name NULLS LAST, src

WITH
sales_agg AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       i.i_category,
       d.d_year,
       SUM(cs.cs_net_paid) AS store_net_paid,
       SUM(cs.cs_net_profit) AS store_profit,
       SUM(cs.cs_quantity) AS store_qty,
       SUM(cs.cs_ext_discount_amt) AS store_discount
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE cs.cs_net_paid IS NOT NULL
   GROUP BY i.i_item_sk, i.i_product_name, i.i_category, d.d_year
),
returns_agg AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       i.i_category,
       d.d_year,
       SUM(cr.cr_return_amount) AS catalog_return_amount,
       SUM(cr.cr_net_loss) AS catalog_return_loss,
       COUNT(*) AS catalog_return_cnt
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   GROUP BY i.i_item_sk, i.i_product_name, i.i_category, d.d_year
),
combined AS (
   SELECT
       COALESCE(s.i_item_sk, r.i_item_sk) AS i_item_sk,
       COALESCE(s.i_product_name, r.i_product_name) AS i_product_name,
       COALESCE(s.i_category, r.i_category) AS i_category,
       COALESCE(s.d_year, r.d_year) AS d_year,
       s.store_net_paid,
       s.store_profit,
       s.store_qty,
       s.store_discount,
       r.catalog_return_amount,
       r.catalog_return_loss,
       r.catalog_return_cnt,
       (COALESCE(s.store_net_paid, 0) - COALESCE(r.catalog_return_amount, 0)) AS net_sales_minus_returns,
       CASE
         WHEN COALESCE(s.store_profit, 0) > 0 THEN 'PROFITABLE'
         WHEN COALESCE(s.store_profit, 0) = 0 THEN 'BREAK-EVEN'
         ELSE 'LOSS'
       END AS profit_status,
       CONCAT(
         COALESCE(s.i_category, 'UNKNOWN'),
         '-',
         CASE WHEN s.store_qty IS NULL THEN 'NO_SALES' ELSE CAST(s.store_qty AS VARCHAR) END,
         '-',
         CASE WHEN r.catalog_return_cnt IS NULL THEN 'NO_RETURNS' ELSE CAST(r.catalog_return_cnt AS VARCHAR) END
       ) AS composite_key,
       ROW_NUMBER() OVER (
         PARTITION BY COALESCE(s.i_category, r.i_category)
         ORDER BY (COALESCE(s.store_net_paid, 0) - COALESCE(r.catalog_return_amount, 0)) DESC NULLS LAST
       ) AS rank_by_net,
       (SELECT MAX(cs_sub.cs_ext_discount_amt)
        FROM catalog_sales cs_sub
        JOIN date_dim d_sub ON cs_sub.cs_sold_date_sk = d_sub.d_date_sk
        WHERE cs_sub.cs_item_sk = COALESCE(s.i_item_sk, r.i_item_sk)
          AND d_sub.d_year = COALESCE(s.d_year, r.d_year)
          AND cs_sub.cs_ext_discount_amt IS NOT NULL) AS max_discount_in_year
   FROM sales_agg s
   FULL OUTER JOIN returns_agg r
       ON s.i_item_sk = r.i_item_sk AND s.d_year = r.d_year
),
top_items AS (
   SELECT *
   FROM combined
   WHERE rank_by_net <= 10
),
store_web_sales AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       i.i_category,
       d.d_year,
       SUM(ss.ss_net_paid) AS store_net_paid,
       SUM(ss.ss_net_profit) AS store_profit,
       SUM(ss.ss_quantity) AS store_qty,
       NULL AS store_discount,
       NULL AS catalog_return_amount,
       NULL AS catalog_return_loss,
       NULL AS catalog_return_cnt,
       NULL AS rank_by_net,
       NULL AS max_discount_in_year,
       NULL AS composite_key,
       NULL AS profit_status
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY i.i_item_sk, i.i_product_name, i.i_category, d.d_year
   UNION ALL
   SELECT
       i.i_item_sk,
       i.i_product_name,
       i.i_category,
       d.d_year,
       SUM(ws.ws_net_paid) AS store_net_paid,
       SUM(ws.ws_net_profit) AS store_profit,
       SUM(ws.ws_quantity) AS store_qty,
       NULL AS store_discount,
       NULL AS catalog_return_amount,
       NULL AS catalog_return_loss,
       NULL AS catalog_return_cnt,
       NULL AS rank_by_net,
       NULL AS max_discount_in_year,
       NULL AS composite_key,
       NULL AS profit_status
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   GROUP BY i.i_item_sk, i.i_product_name, i.i_category, d.d_year
),
item_recent_trans AS (
   SELECT
       o.i_item_sk,
       COUNT(*) AS recent_txn_cnt
   FROM (
       SELECT cs.cs_item_sk AS i_item_sk, cs.cs_sold_date_sk AS sold_date_sk
       FROM catalog_sales cs
       UNION ALL
       SELECT ss.ss_item_sk AS i_item_sk, ss.ss_sold_date_sk AS sold_date_sk
       FROM store_sales ss
       UNION ALL
       SELECT ws.ws_item_sk AS i_item_sk, ws.ws_sold_date_sk AS sold_date_sk
       FROM web_sales ws
   ) o
   JOIN date_dim dd ON o.sold_date_sk = dd.d_date_sk
   WHERE dd.d_year = (SELECT MAX(d2.d_year) FROM date_dim d2)
   GROUP BY o.i_item_sk
)
SELECT
   ti.i_item_sk,
   ti.i_product_name,
   ti.i_category,
   ti.d_year,
   ti.net_sales_minus_returns,
   ti.profit_status,
   ti.composite_key,
   ti.max_discount_in_year,
   COALESCE(rt.recent_txn_cnt, 0) AS recent_txn_cnt,
   CASE
     WHEN (ti.store_net_paid IS NULL AND ti.store_profit IS NULL) OR (ti.net_sales_minus_returns > 10000) THEN 'HIGH-INTEREST'
     ELSE 'NORMAL'
   END AS interest_flag,
   CASE WHEN tws.store_net_paid IS NOT NULL THEN 'IN_STORE_WEB' ELSE 'MISSING' END AS presence_flag
FROM top_items ti
LEFT JOIN store_web_sales tws
   ON ti.i_item_sk = tws.i_item_sk AND ti.d_year = tws.d_year
LEFT JOIN item_recent_trans rt
   ON ti.i_item_sk = rt.i_item_sk
WHERE (ti.rank_by_net = 1 OR ti.rank_by_net = 2)
  AND ti.composite_key LIKE '%-%' ESCAPE '\\'
  AND (ti.max_discount_in_year IS NOT NULL OR ti.max_discount_in_year IS NULL)
ORDER BY ti.i_category, ti.rank_by_net

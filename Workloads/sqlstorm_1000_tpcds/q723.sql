WITH
sales_agg AS (
   SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      d.d_year,
      d.d_month_seq,
      cs.cs_call_center_sk,
      SUM(cs.cs_ext_sales_price) AS cat_sales,
      SUM(cs.cs_net_profit) AS cat_profit,
      SUM(CASE WHEN cs.cs_quantity = 0 THEN NULL ELSE cs.cs_ext_sales_price / cs.cs_quantity END) AS cat_avg_price,
      COUNT(DISTINCT cs.cs_order_number) AS cat_orders,
      MAX(cs.cs_sold_date_sk) AS last_sold_date_sk
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   GROUP BY GROUPING SETS (
        (i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq, cs.cs_call_center_sk),
        (i.i_item_sk, i.i_item_id, i.i_product_name, cs.cs_call_center_sk)
   )
),
call_center_join AS (
   SELECT
      ca.*,
      cc.cc_name,
      cc.cc_gmt_offset
   FROM sales_agg ca
   LEFT JOIN call_center cc ON ca.cs_call_center_sk = cc.cc_call_center_sk
),
store_agg AS (
   SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      d.d_year,
      d.d_month_seq,
      SUM(ss.ss_ext_sales_price) AS store_sales,
      SUM(ss.ss_net_profit) AS store_profit,
      SUM(CASE WHEN ss.ss_quantity = 0 THEN NULL ELSE ss.ss_ext_sales_price / ss.ss_quantity END) AS store_avg_price,
      COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
      MAX(ss.ss_sold_date_sk) AS last_sold_date_sk
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq
),
web_agg AS (
   SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      d.d_year,
      d.d_month_seq,
      SUM(ws.ws_ext_sales_price) AS web_sales,
      SUM(ws.ws_net_profit) AS web_profit,
      SUM(CASE WHEN ws.ws_quantity = 0 THEN NULL ELSE ws.ws_ext_sales_price / ws.ws_quantity END) AS web_avg_price,
      COUNT(DISTINCT ws.ws_order_number) AS web_orders,
      MAX(ws.ws_sold_date_sk) AS last_sold_date_sk
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq
),
returns_agg AS (
   SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      COALESCE(cr.cr_return_amount, sr.sr_return_amt, wr.wr_return_amt) AS return_amt,
      COALESCE(cr.cr_return_quantity, sr.sr_return_quantity, wr.wr_return_quantity) AS return_qty,
      CASE
         WHEN cr.cr_return_amount IS NOT NULL THEN 'Catalog'
         WHEN sr.sr_return_amt IS NOT NULL THEN 'Store'
         WHEN wr.wr_return_amt IS NOT NULL THEN 'Web'
         ELSE 'Unknown'
      END AS return_source,
      COALESCE(cr.cr_returned_date_sk, sr.sr_returned_date_sk, wr.wr_returned_date_sk) AS return_date_sk
   FROM (SELECT * FROM catalog_returns) cr
   FULL OUTER JOIN (SELECT * FROM store_returns) sr
      ON cr.cr_item_sk = sr.sr_item_sk AND cr.cr_returned_date_sk = sr.sr_returned_date_sk
   FULL OUTER JOIN (SELECT * FROM web_returns) wr
      ON COALESCE(cr.cr_item_sk, sr.sr_item_sk) = wr.wr_item_sk
         AND COALESCE(cr.cr_returned_date_sk, sr.sr_returned_date_sk) = wr.wr_returned_date_sk
   JOIN item i ON i.i_item_sk = COALESCE(cr.cr_item_sk, sr.sr_item_sk, wr.wr_item_sk)
   WHERE i.i_item_sk IS NOT NULL
),
combined AS (
   SELECT
      COALESCE(cj.i_item_sk, sa.i_item_sk, wa.i_item_sk) AS i_item_sk,
      COALESCE(cj.i_item_id, sa.i_item_id, wa.i_item_id) AS i_item_id,
      COALESCE(cj.i_product_name, sa.i_product_name, wa.i_product_name) AS i_product_name,
      COALESCE(cj.d_year, sa.d_year, wa.d_year) AS d_year,
      COALESCE(cj.d_month_seq, sa.d_month_seq, wa.d_month_seq) AS d_month_seq,
      COALESCE(cj.cat_sales, 0) - COALESCE(ra.return_amt, 0) AS net_cat_sales,
      COALESCE(sa.store_sales, 0) - COALESCE(ra.return_amt, 0) AS net_store_sales,
      COALESCE(wa.web_sales, 0) - COALESCE(ra.return_amt, 0) AS net_web_sales,
      (COALESCE(cj.cat_profit, 0) + COALESCE(sa.store_profit, 0) + COALESCE(wa.web_profit, 0)) - COALESCE(ra.return_amt, 0) AS total_net_profit,
      CAST(date_add('day', COALESCE(cj.last_sold_date_sk, sa.last_sold_date_sk, wa.last_sold_date_sk), DATE '1970-01-01') AS VARCHAR) AS last_sold_date,
      ROW_NUMBER() OVER (
         PARTITION BY COALESCE(cj.i_item_sk, sa.i_item_sk, wa.i_item_sk)
         ORDER BY (COALESCE(cj.cat_sales, 0) + COALESCE(sa.store_sales, 0) + COALESCE(wa.web_sales, 0)) DESC
      ) AS sales_rank,
      (SELECT COUNT(*) FROM catalog_returns cr2
       WHERE cr2.cr_item_sk = COALESCE(cj.i_item_sk, sa.i_item_sk, wa.i_item_sk)
         AND cr2.cr_return_quantity > 5) AS high_qty_return_cnt,
      COALESCE(cj.cc_name, 'NoCallCenter') AS call_center_name,
      cj.cc_gmt_offset
   FROM call_center_join cj
   FULL OUTER JOIN store_agg sa
      ON cj.i_item_sk = sa.i_item_sk AND cj.d_year = sa.d_year AND cj.d_month_seq = sa.d_month_seq
   FULL OUTER JOIN web_agg wa
      ON COALESCE(cj.i_item_sk, sa.i_item_sk) = wa.i_item_sk
         AND COALESCE(cj.d_year, sa.d_year) = wa.d_year
         AND COALESCE(cj.d_month_seq, sa.d_month_seq) = wa.d_month_seq
   LEFT JOIN returns_agg ra
      ON ra.i_item_sk = COALESCE(cj.i_item_sk, sa.i_item_sk, wa.i_item_sk)
   WHERE (COALESCE(cj.cat_sales, 0) + COALESCE(sa.store_sales, 0) + COALESCE(wa.web_sales, 0)) > 0
),
filtered AS (
   SELECT *
   FROM combined
   WHERE total_net_profit > 0 OR high_qty_return_cnt > 0
)
SELECT
   i_item_sk,
   i_item_id,
   i_product_name,
   d_year,
   d_month_seq,
   net_cat_sales,
   net_store_sales,
   net_web_sales,
   total_net_profit,
   last_sold_date,
   sales_rank,
   high_qty_return_cnt,
   CASE
      WHEN total_net_profit > 0 THEN concat('Profit+', CAST(total_net_profit AS VARCHAR))
      WHEN total_net_profit < 0 THEN concat('Loss', CAST(total_net_profit AS VARCHAR))
      ELSE 'BreakEven'
   END AS profit_label,
   CASE WHEN high_qty_return_cnt > 0 THEN 'HasHighReturn' END AS high_return_flag,
   call_center_name,
   CAST(cc_gmt_offset AS VARCHAR) AS cc_gmt_offset
FROM (
   SELECT *
   FROM filtered
   ORDER BY total_net_profit DESC, sales_rank ASC
   LIMIT 100
) top
UNION ALL
SELECT
   NULL,
   NULL,
   'TOTAL',
   NULL,
   NULL,
   SUM(net_cat_sales) OVER (),
   SUM(net_store_sales) OVER (),
   SUM(net_web_sales) OVER (),
   SUM(total_net_profit) OVER (),
   NULL,
   NULL,
   NULL,
   CASE WHEN SUM(total_net_profit) OVER () > 0 THEN 'OverallProfit' ELSE 'OverallLoss' END,
   NULL,
   NULL,
   NULL
FROM combined

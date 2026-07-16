WITH
sales_union AS (
   SELECT 'store' AS channel,
          ss.ss_sold_date_sk AS date_sk,
          ss.ss_item_sk AS item_sk,
          ss.ss_customer_sk AS cust_sk,
          ss.ss_quantity AS quantity,
          ss.ss_net_paid AS net_paid,
          ss.ss_net_profit AS net_profit,
          ss.ss_store_sk AS store_sk,
          CAST(NULL AS INTEGER) AS catalog_page_sk,
          CAST(NULL AS INTEGER) AS web_page_sk,
          ss.ss_promo_sk AS promo_sk,
          CAST(NULL AS INTEGER) AS call_center_sk
   FROM store_sales ss
   UNION ALL
   SELECT 'catalog' AS channel,
          cs.cs_sold_date_sk AS date_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_bill_customer_sk AS cust_sk,
          cs.cs_quantity AS quantity,
          cs.cs_net_paid AS net_paid,
          cs.cs_net_profit AS net_profit,
          CAST(NULL AS INTEGER) AS store_sk,
          cs.cs_catalog_page_sk AS catalog_page_sk,
          CAST(NULL AS INTEGER) AS web_page_sk,
          cs.cs_promo_sk AS promo_sk,
          cs.cs_call_center_sk AS call_center_sk
   FROM catalog_sales cs
   UNION ALL
   SELECT 'web' AS channel,
          ws.ws_sold_date_sk AS date_sk,
          ws.ws_item_sk AS item_sk,
          ws.ws_bill_customer_sk AS cust_sk,
          ws.ws_quantity AS quantity,
          ws.ws_net_paid AS net_paid,
          ws.ws_net_profit AS net_profit,
          CAST(NULL AS INTEGER) AS store_sk,
          CAST(NULL AS INTEGER) AS catalog_page_sk,
          ws.ws_web_page_sk AS web_page_sk,
          ws.ws_promo_sk AS promo_sk,
          CAST(NULL AS INTEGER) AS call_center_sk
   FROM web_sales ws
),
returns_union AS (
   SELECT 'store' AS channel,
          sr.sr_returned_date_sk AS date_sk,
          sr.sr_item_sk AS item_sk,
          sr.sr_customer_sk AS cust_sk,
          sr.sr_return_quantity AS quantity,
          sr.sr_return_amt AS return_amount,
          sr.sr_net_loss AS net_loss,
          sr.sr_store_sk AS store_sk,
          CAST(NULL AS INTEGER) AS catalog_page_sk,
          CAST(NULL AS INTEGER) AS web_page_sk
   FROM store_returns sr
   UNION ALL
   SELECT 'catalog' AS channel,
          cr.cr_returned_date_sk AS date_sk,
          cr.cr_item_sk AS item_sk,
          cr.cr_refunded_customer_sk AS cust_sk,
          cr.cr_return_quantity AS quantity,
          cr.cr_return_amount AS return_amount,
          cr.cr_net_loss AS net_loss,
          CAST(NULL AS INTEGER) AS store_sk,
          cr.cr_catalog_page_sk AS catalog_page_sk,
          CAST(NULL AS INTEGER) AS web_page_sk
   FROM catalog_returns cr
   UNION ALL
   SELECT 'web' AS channel,
          wr.wr_returned_date_sk AS date_sk,
          wr.wr_item_sk AS item_sk,
          wr.wr_refunded_customer_sk AS cust_sk,
          wr.wr_return_quantity AS quantity,
          wr.wr_return_amt AS return_amount,
          wr.wr_net_loss AS net_loss,
          CAST(NULL AS INTEGER) AS store_sk,
          CAST(NULL AS INTEGER) AS catalog_page_sk,
          wr.wr_web_page_sk AS web_page_sk
   FROM web_returns wr
),
cust_sales_agg AS (
   SELECT
       su.channel,
       d.d_year AS year,
       d.d_month_seq AS month_seq,
       MIN(d.d_date) AS month_start_date,
       i.i_category,
       i.i_class,
       i.i_brand,
       SUM(su.quantity) AS total_qty,
       SUM(su.net_paid) AS total_revenue,
       SUM(su.net_profit) AS total_profit,
       COUNT(DISTINCT su.cust_sk) AS distinct_customers,
       COUNT(DISTINCT su.item_sk) AS distinct_items,
       ROW_NUMBER() OVER (PARTITION BY d.d_year, su.channel ORDER BY SUM(su.net_paid) DESC) AS revenue_rank
   FROM sales_union su
   JOIN date_dim d ON su.date_sk = d.d_date_sk
   JOIN item i ON su.item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   GROUP BY su.channel, d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
returns_agg_per_cust_month AS (
   SELECT
       r.channel,
       c.c_customer_sk AS cust_sk,
       d.d_year,
       d.d_month_seq,
       SUM(r.quantity) AS total_return_qty,
       SUM(r.return_amount) AS total_return_amount
   FROM returns_union r
   JOIN date_dim d ON r.date_sk = d.d_date_sk
   JOIN customer c ON r.cust_sk = c.c_customer_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   GROUP BY r.channel, c.c_customer_sk, d.d_year, d.d_month_seq
),
customer_return_rate AS (
   SELECT
       ca.channel,
       ca.year,
       ca.month_seq,
       SUM(COALESCE(rr.total_return_qty, 0)) * 1.0 / NULLIF(SUM(ca.total_qty), 0) AS return_rate
   FROM cust_sales_agg ca
   LEFT JOIN returns_agg_per_cust_month rr
          ON ca.channel = rr.channel
         AND ca.year = rr.d_year
         AND ca.month_seq = rr.d_month_seq
   GROUP BY ca.channel, ca.year, ca.month_seq
),
final_report AS (
   SELECT
       ca.channel,
       CONCAT('YR', CAST(ca.year AS VARCHAR), '-M', LPAD(CAST(((ca.month_seq - 1) % 12) + 1 AS VARCHAR), 2, '0')) AS period,
       ca.i_category,
       ca.i_class,
       ca.i_brand,
       ca.total_qty,
       ca.total_revenue,
       ca.total_profit,
       ca.distinct_customers,
       ca.distinct_items,
       ca.revenue_rank,
       COALESCE(cr.return_rate, 0) AS return_rate,
       CASE
           WHEN ca.total_profit > 0 THEN 'POSITIVE'
           WHEN ca.total_profit < 0 THEN 'NEGATIVE'
           ELSE 'ZERO'
       END AS profit_status,
       COALESCE(cc.cc_name, 'N/A') AS call_center_name,
       COALESCE(p.p_promo_name, 'N/A') AS promo_name,
       (SELECT SUM(su2.net_paid)
        FROM sales_union su2
        JOIN date_dim d2 ON su2.date_sk = d2.d_date_sk
        WHERE su2.channel = ca.channel
          AND d2.d_year = ca.year
          AND d2.d_month_seq = ca.month_seq) AS channel_month_total_spend,
       SUM(ca.total_profit) OVER (PARTITION BY ca.channel, ca.i_category ORDER BY ca.year, ca.month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_last_3_months,
       CONCAT('Category_', COALESCE(NULLIF(TRIM(ca.i_category), ''), 'UNKNOWN')) AS category_key,
       ca.month_start_date + INTERVAL '1' MONTH AS next_month_date
   FROM cust_sales_agg ca
   LEFT JOIN customer_return_rate cr
          ON ca.channel = cr.channel
         AND ca.year = cr.year
         AND ca.month_seq = cr.month_seq
   LEFT JOIN (
       SELECT channel, MAX(call_center_sk) AS call_center_sk
       FROM sales_union
       WHERE call_center_sk IS NOT NULL
       GROUP BY channel
   ) cc_map ON ca.channel = cc_map.channel
   LEFT JOIN call_center cc ON cc_map.call_center_sk = cc.cc_call_center_sk
   LEFT JOIN (
       SELECT channel, MAX(promo_sk) AS promo_sk
       FROM sales_union
       WHERE promo_sk IS NOT NULL
       GROUP BY channel
   ) promo_map ON ca.channel = promo_map.channel
   LEFT JOIN promotion p ON promo_map.promo_sk = p.p_promo_sk
)
SELECT *
FROM final_report
WHERE revenue_rank <= 10
ORDER BY channel, period, revenue_rank

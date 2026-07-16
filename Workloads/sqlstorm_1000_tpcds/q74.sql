WITH
 sold_items AS (
   SELECT ss_item_sk AS item_sk,
          ss_sold_date_sk AS date_sk,
          ss_customer_sk AS customer_sk,
          'store' AS channel,
          ss_net_paid AS net_paid,
          ss_quantity AS qty
   FROM store_sales
   UNION ALL
   SELECT ws_item_sk,
          ws_sold_date_sk,
          ws_bill_customer_sk,
          'web',
          ws_net_paid,
          ws_quantity
   FROM web_sales
   UNION ALL
   SELECT cs_item_sk,
          cs_sold_date_sk,
          cs_bill_customer_sk,
          'catalog',
          cs_net_paid,
          cs_quantity
   FROM catalog_sales
 ),
 returned_items AS (
   SELECT sr_item_sk AS item_sk,
          sr_returned_date_sk AS date_sk,
          sr_customer_sk AS customer_sk,
          'store' AS channel,
          sr_net_loss AS net_loss,
          sr_return_quantity AS qty
   FROM store_returns
   UNION ALL
   SELECT wr_item_sk,
          wr_returned_date_sk,
          wr_refunded_customer_sk,
          'web',
          wr_net_loss,
          wr_return_quantity
   FROM web_returns
   UNION ALL
   SELECT cr_item_sk,
          cr_returned_date_sk,
          cr_refunded_customer_sk,
          'catalog',
          cr_net_loss,
          cr_return_quantity
   FROM catalog_returns
 ),
 sales_agg AS (
   SELECT
     si.item_sk,
     si.date_sk,
     COUNT(*) AS sales_txn_cnt,
     SUM(si.net_paid) AS total_net_paid,
     AVG(si.net_paid) AS avg_net_paid,
     SUM(si.qty) AS total_qty_sold,
     MAX(si.net_paid) AS max_net_paid,
     MIN(si.net_paid) AS min_net_paid
   FROM sold_items si
   GROUP BY si.item_sk, si.date_sk
 ),
 returns_agg AS (
   SELECT
     ri.item_sk,
     ri.date_sk,
     COUNT(*) AS return_txn_cnt,
     SUM(ri.net_loss) AS total_net_loss,
     AVG(ri.net_loss) AS avg_net_loss,
     SUM(ri.qty) AS total_qty_returned
   FROM returned_items ri
   GROUP BY ri.item_sk, ri.date_sk
 ),
 combined AS (
   SELECT
     COALESCE(s.item_sk, r.item_sk) AS item_sk,
     COALESCE(s.date_sk, r.date_sk) AS date_sk,
     s.sales_txn_cnt,
     s.total_net_paid,
     s.avg_net_paid,
     s.total_qty_sold,
     r.return_txn_cnt,
     r.total_net_loss,
     r.avg_net_loss,
     r.total_qty_returned
   FROM sales_agg s
   FULL OUTER JOIN returns_agg r
     ON s.item_sk = r.item_sk AND s.date_sk = r.date_sk
 ),
 final_metrics AS (
   SELECT
     c.item_sk,
     c.date_sk,
     COALESCE(c.sales_txn_cnt, 0) AS sales_txn_cnt,
     COALESCE(c.total_net_paid, 0.0) AS total_net_paid,
     COALESCE(c.total_qty_sold, 0) AS total_qty_sold,
     COALESCE(c.return_txn_cnt, 0) AS return_txn_cnt,
     COALESCE(c.total_net_loss, 0.0) AS total_net_loss,
     COALESCE(c.total_qty_returned, 0) AS total_qty_returned,
     CASE
       WHEN (c.total_net_paid + c.total_net_loss) = 0 THEN NULL
       ELSE c.total_net_paid / NULLIF(c.total_net_paid + c.total_net_loss, 0)
     END AS profit_margin_ratio,
     ROW_NUMBER() OVER (PARTITION BY c.date_sk ORDER BY COALESCE(c.total_net_paid, 0) DESC) AS sales_rank_by_date,
     SUM(COALESCE(c.total_net_paid, 0)) OVER (PARTITION BY c.item_sk ORDER BY c.date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
     (SELECT COUNT(DISTINCT si2.customer_sk)
        FROM sold_items si2
        WHERE si2.item_sk = c.item_sk) AS distinct_customers,
     CONCAT('Item ', COALESCE(i.i_item_id, 'UNKNOWN'), ' on ', CAST(d.d_date AS VARCHAR)) AS item_date_desc,
     CASE WHEN i.i_item_desc IS NULL THEN 'NO_DESC' ELSE i.i_item_desc END AS item_desc,
     CASE
       WHEN (COALESCE(c.sales_txn_cnt, 0) > 10 AND COALESCE(c.return_txn_cnt, 0) = 0)
            OR (COALESCE(c.return_txn_cnt, 0) > 5 AND COALESCE(c.sales_txn_cnt, 0) = 0)
       THEN 'ANOMALOUS' ELSE 'NORMAL'
     END AS anomaly_flag
   FROM combined c
   LEFT JOIN item i ON c.item_sk = i.i_item_sk
   LEFT JOIN date_dim d ON c.date_sk = d.d_date_sk
 ),
 sold_without_return AS (
   SELECT DISTINCT item_sk, date_sk FROM sales_agg
   EXCEPT
   SELECT DISTINCT item_sk, date_sk FROM returns_agg
 ),
 final_output AS (
   SELECT fm.*, 'SALES' AS source
   FROM final_metrics fm
   UNION ALL
   SELECT
     swr.item_sk,
     swr.date_sk,
     NULL AS sales_txn_cnt,
     NULL AS total_net_paid,
     NULL AS total_qty_sold,
     NULL AS return_txn_cnt,
     NULL AS total_net_loss,
     NULL AS total_qty_returned,
     NULL AS profit_margin_ratio,
     NULL AS sales_rank_by_date,
     NULL AS cumulative_net_paid,
     (SELECT COUNT(DISTINCT si3.customer_sk)
        FROM sold_items si3
        WHERE si3.item_sk = swr.item_sk) AS distinct_customers,
     CONCAT('Item ', COALESCE(i2.i_item_id, 'UNKNOWN'), ' on ', CAST(d2.d_date AS VARCHAR)) AS item_date_desc,
     CASE WHEN i2.i_item_desc IS NULL THEN 'NO_DESC' ELSE i2.i_item_desc END AS item_desc,
     'NO_RETURN' AS anomaly_flag,
     'NO_RETURN' AS source
   FROM sold_without_return swr
   LEFT JOIN item i2 ON swr.item_sk = i2.i_item_sk
   LEFT JOIN date_dim d2 ON swr.date_sk = d2.d_date_sk
 )
SELECT *
FROM final_output
ORDER BY
  item_sk NULLS LAST,
  date_sk NULLS LAST,
  source,
  sales_rank_by_date

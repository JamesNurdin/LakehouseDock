WITH
  base_catalog AS (
    SELECT
      cs.cs_item_sk AS item_sk,
      i.i_category AS category,
      d.d_year AS sale_year,
      d.d_month_seq AS month_seq,
      cs.cs_quantity AS quantity,
      cs.cs_net_profit AS net_profit,
      cs.cs_ext_discount_amt AS discount_amt,
      cr.cr_return_quantity AS return_quantity,
      cr.cr_net_loss AS return_net_loss,
      r.r_reason_desc AS return_reason,
      (cs.cs_quantity - COALESCE(cr.cr_return_quantity, 0)) AS net_quantity,
      (cs.cs_net_profit - COALESCE(cr.cr_net_loss, 0)) AS net_profit_adj
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
      AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
  ),
  base_store AS (
    SELECT
      ss.ss_item_sk AS item_sk,
      i.i_category AS category,
      d.d_year AS sale_year,
      d.d_month_seq AS month_seq,
      ss.ss_quantity AS quantity,
      ss.ss_net_profit AS net_profit,
      ss.ss_ext_discount_amt AS discount_amt,
      sr.sr_return_quantity AS return_quantity,
      sr.sr_net_loss AS return_net_loss,
      r.r_reason_desc AS return_reason,
      (ss.ss_quantity - COALESCE(sr.sr_return_quantity, 0)) AS net_quantity,
      (ss.ss_net_profit - COALESCE(sr.sr_net_loss, 0)) AS net_profit_adj
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
      AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
  ),
  base_web AS (
    SELECT
      ws.ws_item_sk AS item_sk,
      i.i_category AS category,
      d.d_year AS sale_year,
      d.d_month_seq AS month_seq,
      ws.ws_quantity AS quantity,
      ws.ws_net_profit AS net_profit,
      ws.ws_ext_discount_amt AS discount_amt,
      wr.wr_return_quantity AS return_quantity,
      wr.wr_net_loss AS return_net_loss,
      r.r_reason_desc AS return_reason,
      (ws.ws_quantity - COALESCE(wr.wr_return_quantity, 0)) AS net_quantity,
      (ws.ws_net_profit - COALESCE(wr.wr_net_loss, 0)) AS net_profit_adj
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
      AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
  ),
  unified_sales AS (
    SELECT * FROM base_catalog
    UNION ALL
    SELECT * FROM base_store
    UNION ALL
    SELECT * FROM base_web
  ),
  category_month_base AS (
    SELECT
      category,
      sale_year,
      month_seq,
      SUM(net_quantity) AS total_quantity,
      SUM(net_profit_adj) AS total_profit,
      AVG(discount_amt) AS avg_discount,
      COUNT(*) AS total_sales_rows,
      CONCAT(category, '_', CAST(sale_year AS varchar), '-', LPAD(CAST(month_seq AS varchar), 2, '0')) AS cat_month_key,
      CASE WHEN COUNT(*) FILTER (WHERE return_reason IS NULL) > 0 THEN 'UNKNOWN_REASON' ELSE 'ALL_REPORTED' END AS reason_status
    FROM unified_sales
    GROUP BY category, sale_year, month_seq
  ),
  category_month_agg AS (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_profit DESC) AS profit_rank
    FROM category_month_base
  ),
  max_profit_per_category AS (
    SELECT category, MAX(total_profit) AS max_profit
    FROM category_month_agg
    GROUP BY category
  ),
  top_categories AS (
    SELECT
      cm.category,
      cm.sale_year,
      cm.month_seq,
      cm.total_quantity,
      cm.total_profit,
      cm.avg_discount,
      cm.profit_rank,
      cm.cat_month_key,
      cm.reason_status,
      CASE
        WHEN cm.total_quantity > (
          SELECT AVG(total_quantity)
          FROM category_month_agg cma2
          WHERE cma2.sale_year = cm.sale_year
            AND cma2.month_seq = cm.month_seq
        ) THEN 'ABOVE_AVG_QTY'
        ELSE 'BELOW_OR_EQUAL_AVG_QTY'
      END AS qty_performance,
      ROUND(cm.total_profit * 100.0 / NULLIF(m.max_profit, 0), 2) AS profit_pct_of_max
    FROM category_month_agg cm
    LEFT JOIN max_profit_per_category m ON cm.category = m.category
    WHERE cm.profit_rank <= 5
  )
SELECT
  category,
  sale_year,
  month_seq,
  total_quantity,
  total_profit,
  avg_discount,
  profit_rank,
  cat_month_key,
  reason_status,
  qty_performance,
  profit_pct_of_max
FROM top_categories
EXCEPT
SELECT
  category,
  sale_year,
  month_seq,
  total_quantity,
  total_profit,
  avg_discount,
  profit_rank,
  cat_month_key,
  reason_status,
  qty_performance,
  profit_pct_of_max
FROM top_categories
WHERE reason_status = 'UNKNOWN_REASON'
ORDER BY category, sale_year, month_seq

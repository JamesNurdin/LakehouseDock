WITH
  -- Aggregate store sales per transaction (order + item) and attach date & product info
  store_sales_txn AS (
    SELECT
      ss.ss_ticket_number AS ticket_number,
      ss.ss_item_sk     AS item_sk,
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand,
      SUM(ss.ss_quantity)      AS sales_quantity,
      SUM(ss.ss_net_paid)      AS sales_net_paid,
      SUM(ss.ss_net_profit)    AS sales_net_profit
    FROM store_sales ss
    JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i       ON ss.ss_item_sk = i.i_item_sk
    GROUP BY
      ss.ss_ticket_number,
      ss.ss_item_sk,
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand
  ),
  -- Aggregate store returns per transaction (order + item)
  store_returns_txn AS (
    SELECT
      sr.sr_ticket_number AS ticket_number,
      sr.sr_item_sk      AS item_sk,
      SUM(sr.sr_return_quantity) AS return_quantity,
      SUM(sr.sr_net_loss)        AS return_net_loss
    FROM store_returns sr
    GROUP BY sr.sr_ticket_number, sr.sr_item_sk
  ),
  store_combined AS (
    SELECT
      'store' AS channel,
      s.d_year,
      s.d_month_seq,
      s.i_category,
      s.i_brand,
      s.sales_quantity,
      s.sales_net_paid,
      s.sales_net_profit,
      COALESCE(r.return_quantity, 0) AS return_quantity,
      COALESCE(r.return_net_loss, 0) AS return_net_loss
    FROM store_sales_txn s
    LEFT JOIN store_returns_txn r
      ON s.ticket_number = r.ticket_number
     AND s.item_sk      = r.item_sk
  ),

  -- Aggregate catalog sales per transaction (order + item) and attach date & product info
  catalog_sales_txn AS (
    SELECT
      cs.cs_order_number AS order_number,
      cs.cs_item_sk      AS item_sk,
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand,
      SUM(cs.cs_quantity)      AS sales_quantity,
      SUM(cs.cs_net_paid)      AS sales_net_paid,
      SUM(cs.cs_net_profit)    AS sales_net_profit
    FROM catalog_sales cs
    JOIN date_dim d   ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i       ON cs.cs_item_sk = i.i_item_sk
    GROUP BY
      cs.cs_order_number,
      cs.cs_item_sk,
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand
  ),
  catalog_returns_txn AS (
    SELECT
      cr.cr_order_number AS order_number,
      cr.cr_item_sk      AS item_sk,
      SUM(cr.cr_return_quantity) AS return_quantity,
      SUM(cr.cr_net_loss)        AS return_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_order_number, cr.cr_item_sk
  ),
  catalog_combined AS (
    SELECT
      'catalog' AS channel,
      s.d_year,
      s.d_month_seq,
      s.i_category,
      s.i_brand,
      s.sales_quantity,
      s.sales_net_paid,
      s.sales_net_profit,
      COALESCE(r.return_quantity, 0) AS return_quantity,
      COALESCE(r.return_net_loss, 0) AS return_net_loss
    FROM catalog_sales_txn s
    LEFT JOIN catalog_returns_txn r
      ON s.order_number = r.order_number
     AND s.item_sk      = r.item_sk
  ),

  -- Aggregate web sales per transaction (order + item) and attach date & product info
  web_sales_txn AS (
    SELECT
      ws.ws_order_number AS order_number,
      ws.ws_item_sk      AS item_sk,
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand,
      SUM(ws.ws_quantity)      AS sales_quantity,
      SUM(ws.ws_net_paid)      AS sales_net_paid,
      SUM(ws.ws_net_profit)    AS sales_net_profit
    FROM web_sales ws
    JOIN date_dim d   ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i       ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
      ws.ws_order_number,
      ws.ws_item_sk,
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand
  ),
  web_returns_txn AS (
    SELECT
      wr.wr_order_number AS order_number,
      wr.wr_item_sk      AS item_sk,
      SUM(wr.wr_return_quantity) AS return_quantity,
      SUM(wr.wr_net_loss)        AS return_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_order_number, wr.wr_item_sk
  ),
  web_combined AS (
    SELECT
      'web' AS channel,
      s.d_year,
      s.d_month_seq,
      s.i_category,
      s.i_brand,
      s.sales_quantity,
      s.sales_net_paid,
      s.sales_net_profit,
      COALESCE(r.return_quantity, 0) AS return_quantity,
      COALESCE(r.return_net_loss, 0) AS return_net_loss
    FROM web_sales_txn s
    LEFT JOIN web_returns_txn r
      ON s.order_number = r.order_number
     AND s.item_sk      = r.item_sk
  )
SELECT
  channel,
  d_year,
  d_month_seq,
  i_category,
  i_brand,
  SUM(sales_quantity)   AS total_sales_quantity,
  SUM(sales_net_paid)   AS total_sales_net_paid,
  SUM(sales_net_profit) AS total_sales_net_profit,
  SUM(return_quantity)  AS total_return_quantity,
  SUM(return_net_loss)  AS total_return_net_loss,
  CASE WHEN SUM(sales_quantity) > 0
       THEN SUM(return_quantity) * 100.0 / SUM(sales_quantity)
       ELSE 0
  END AS return_rate_pct,
  CASE WHEN SUM(sales_net_paid) > 0
       THEN SUM(return_net_loss) * 100.0 / SUM(sales_net_paid)
       ELSE 0
  END AS return_loss_pct
FROM (
  SELECT channel, d_year, d_month_seq, i_category, i_brand,
         sales_quantity, sales_net_paid, sales_net_profit,
         return_quantity, return_net_loss
  FROM store_combined
  UNION ALL
  SELECT channel, d_year, d_month_seq, i_category, i_brand,
         sales_quantity, sales_net_paid, sales_net_profit,
         return_quantity, return_net_loss
  FROM catalog_combined
  UNION ALL
  SELECT channel, d_year, d_month_seq, i_category, i_brand,
         sales_quantity, sales_net_paid, sales_net_profit,
         return_quantity, return_net_loss
  FROM web_combined
) combined
GROUP BY channel, d_year, d_month_seq, i_category, i_brand
ORDER BY channel, d_year, d_month_seq, i_category, i_brand

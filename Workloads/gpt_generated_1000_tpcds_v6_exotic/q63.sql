WITH
  sales_agg AS (
    SELECT
      i.i_category AS category,
      ws.ws_sold_date_sk AS date_key,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(*) AS txn_cnt,
      'sale' AS src
    FROM tpcds.web_sales ws
    JOIN tpcds.item i
      ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451170
    GROUP BY i.i_category, ws.ws_sold_date_sk
  ),
  returns_agg AS (
    SELECT
      i.i_category AS category,
      wr.wr_returned_date_sk AS date_key,
      -SUM(wr.wr_return_amt) AS total_sales,
      -SUM(wr.wr_net_loss) AS total_profit,
      COUNT(*) AS txn_cnt,
      'return' AS src
    FROM tpcds.web_returns wr
    JOIN tpcds.item i
      ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2451170
    GROUP BY i.i_category, wr.wr_returned_date_sk
  )
SELECT
  combined.category,
  combined.date_key,
  SUM(combined.total_sales) AS net_sales_amount,
  SUM(combined.total_profit) AS net_profit_amount,
  SUM(combined.txn_cnt) AS total_transactions,
  CASE WHEN SUM(combined.total_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM (
  SELECT * FROM sales_agg
  UNION ALL
  SELECT * FROM returns_agg
) AS combined
GROUP BY combined.category, combined.date_key
ORDER BY net_sales_amount DESC
LIMIT 20

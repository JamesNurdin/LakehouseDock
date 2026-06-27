WITH
  sales_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category AS category,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_net_profit,
      SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
  ),
  returns_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category AS category,
      SUM(wr.wr_return_amt) AS total_return_amount,
      SUM(wr.wr_return_quantity) AS total_return_quantity,
      SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
  )
SELECT
  s.d_year,
  s.d_month_seq,
  s.category,
  s.total_sales,
  s.total_quantity_sold,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
  s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
  CAST(COALESCE(r.total_return_quantity, 0) AS DOUBLE) / NULLIF(s.total_quantity_sold, 0) AS return_rate
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
 AND s.d_month_seq = r.d_month_seq
 AND s.category = r.category
ORDER BY s.d_year, s.d_month_seq, s.category

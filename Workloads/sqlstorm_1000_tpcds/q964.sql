WITH
  unified_sales AS (
    SELECT
      ss.ss_sold_date_sk AS sold_date_sk,
      ss.ss_item_sk AS item_sk,
      ss.ss_store_sk AS store_sk,
      ss.ss_quantity AS quantity,
      ss.ss_net_paid AS net_paid,
      ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
      ss.ss_net_profit AS net_profit,
      'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      NULL,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_net_paid_inc_tax,
      ws.ws_net_profit,
      'web' AS channel
    FROM web_sales ws
    UNION ALL
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_item_sk,
      NULL,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_paid_inc_tax,
      cs.cs_net_profit,
      'catalog' AS channel
    FROM catalog_sales cs
  ),
  returns_raw AS (
    SELECT
      sr.sr_returned_date_sk AS returned_date_sk,
      sr.sr_item_sk AS item_sk,
      SUM(sr.sr_return_quantity) AS return_qty
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk
    UNION ALL
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      SUM(wr.wr_return_quantity) AS return_qty
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
  ),
  returns_agg AS (
    SELECT
      returned_date_sk,
      item_sk,
      SUM(return_qty) AS return_qty
    FROM returns_raw
    GROUP BY returned_date_sk, item_sk
  ),
  sales_with_dim AS (
    SELECT
      us.*,
      d.d_year,
      d.d_quarter_seq,
      i.i_category,
      i.i_class,
      i.i_brand,
      i.i_color,
      s.s_state,
      s.s_city,
      COALESCE(r.return_qty, 0) AS return_qty
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    LEFT JOIN store s ON us.store_sk = s.s_store_sk
    LEFT JOIN returns_agg r ON us.sold_date_sk = r.returned_date_sk AND us.item_sk = r.item_sk
  ),
  aggregated AS (
    SELECT
      d_year,
      d_quarter_seq,
      i_category,
      i_class,
      i_brand,
      i_color,
      s_state,
      channel,
      SUM(quantity) AS total_quantity,
      SUM(net_paid) AS total_net_paid,
      SUM(net_paid_inc_tax) AS total_net_paid_inc_tax,
      SUM(net_profit) AS total_net_profit,
      SUM(return_qty) AS total_return_quantity,
      AVG(net_profit) AS avg_net_profit,
      COUNT(*) AS sales_count
    FROM sales_with_dim
    GROUP BY
      d_year,
      d_quarter_seq,
      i_category,
      i_class,
      i_brand,
      i_color,
      s_state,
      channel
  ),
  ranked AS (
    SELECT
      a.*,
      ROW_NUMBER() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY total_net_profit DESC) AS profit_rank,
      CASE WHEN total_quantity > 0 THEN total_return_quantity * 100.0 / total_quantity ELSE 0 END AS return_rate_percent
    FROM aggregated a
  )
SELECT
  d_year,
  d_quarter_seq,
  i_category,
  i_class,
  i_brand,
  i_color,
  s_state,
  channel,
  total_quantity,
  total_net_paid,
  total_net_paid_inc_tax,
  total_net_profit,
  avg_net_profit,
  total_return_quantity,
  return_rate_percent,
  sales_count,
  profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, d_quarter_seq, profit_rank

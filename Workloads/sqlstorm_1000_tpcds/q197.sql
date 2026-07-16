WITH sales_agg AS (
   SELECT d.d_year,
          i.i_category,
          sum(ss.ss_net_profit) AS profit,
          sum(ss.ss_quantity) AS quantity,
          count(*) AS txns,
          'store' AS channel
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
   GROUP BY d.d_year, i.i_category
   UNION ALL
   SELECT d.d_year,
          i.i_category,
          sum(cs.cs_net_profit) AS profit,
          sum(cs.cs_quantity) AS quantity,
          count(*) AS txns,
          'catalog' AS channel
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
   GROUP BY d.d_year, i.i_category
   UNION ALL
   SELECT d.d_year,
          i.i_category,
          sum(ws.ws_net_profit) AS profit,
          sum(ws.ws_quantity) AS quantity,
          count(*) AS txns,
          'web' AS channel
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
   GROUP BY d.d_year, i.i_category
),
returns_agg AS (
   SELECT d.d_year,
          i.i_category,
          sum(r.net_loss) AS return_loss
   FROM (
        SELECT cr_returned_date_sk AS date_sk, cr_item_sk AS item_sk, cr_net_loss AS net_loss
        FROM catalog_returns
        UNION ALL
        SELECT sr_returned_date_sk, sr_item_sk, sr_net_loss
        FROM store_returns
        UNION ALL
        SELECT wr_returned_date_sk, wr_item_sk, wr_net_loss
        FROM web_returns
   ) r
   JOIN date_dim d ON r.date_sk = d.d_date_sk
   JOIN item i ON r.item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
   GROUP BY d.d_year, i.i_category
),
combined AS (
   SELECT s.d_year,
          s.i_category,
          sum(s.profit) AS gross_profit,
          sum(s.quantity) AS total_qty,
          sum(s.txns) AS total_txns,
          sum(s.profit) - coalesce(max(r.return_loss), 0) AS net_profit
   FROM sales_agg s
   LEFT JOIN returns_agg r
      ON s.d_year = r.d_year AND s.i_category = r.i_category
   GROUP BY s.d_year, s.i_category
)
SELECT
   d_year,
   i_category,
   net_profit,
   total_qty,
   total_txns,
   net_profit / nullif(total_qty, 0) AS profit_per_qty,
   rank() OVER (ORDER BY net_profit DESC) AS profit_rank,
   avg(net_profit) OVER (PARTITION BY i_category ORDER BY d_year ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS moving_avg_5yr_profit,
   sum(net_profit) OVER (PARTITION BY d_year) AS total_profit_year,
   max(net_profit) OVER (PARTITION BY d_year) AS max_profit_year,
   min(net_profit) OVER (PARTITION BY d_year) AS min_profit_year,
   sum(net_profit) OVER (PARTITION BY i_category ORDER BY d_year ROWS UNBOUNDED PRECEDING) AS cumulative_profit_category
FROM combined
WHERE net_profit IS NOT NULL
ORDER BY net_profit DESC
LIMIT 100

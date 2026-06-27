WITH all_transactions AS (
    -- Sales from the three channels (store, catalog, web)
    SELECT d.d_year AS year,
           d.d_moy  AS month,
           i.i_category AS category,
           ss.ss_net_profit AS profit,
           CAST(0 AS decimal(7,2)) AS loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year,
           d.d_moy,
           i.i_category,
           cs.cs_net_profit,
           CAST(0 AS decimal(7,2))
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year,
           d.d_moy,
           i.i_category,
           ws.ws_net_profit,
           CAST(0 AS decimal(7,2))
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk

    UNION ALL

    -- Returns (losses) from the three channels
    SELECT d.d_year,
           d.d_moy,
           i.i_category,
           CAST(0 AS decimal(7,2)) AS profit,
           sr.sr_net_loss AS loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year,
           d.d_moy,
           i.i_category,
           CAST(0 AS decimal(7,2)),
           cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year,
           d.d_moy,
           i.i_category,
           CAST(0 AS decimal(7,2)),
           wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
agg AS (
    SELECT year,
           month,
           category,
           SUM(profit) AS total_profit,
           SUM(loss)   AS total_loss,
           SUM(profit) - SUM(loss) AS net_profit
    FROM all_transactions
    GROUP BY year, month, category
)
SELECT year,
       month,
       category,
       total_profit,
       total_loss,
       net_profit,
       ROUND(
           net_profit / NULLIF(SUM(net_profit) OVER (PARTITION BY year, month), 0) * 100,
           2
       ) AS profit_pct_of_month,
       ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY net_profit DESC) AS profit_rank_by_month
FROM agg
ORDER BY year, month, profit_rank_by_month

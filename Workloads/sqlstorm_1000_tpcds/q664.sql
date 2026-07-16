WITH sales_agg AS (
    SELECT s.date_sk,
           s.channel,
           s.item_sk,
           i.i_category,
           SUM(s.net_profit) AS profit
    FROM (
        SELECT ss.ss_sold_date_sk AS date_sk,
               'store' AS channel,
               ss.ss_item_sk AS item_sk,
               ss.ss_net_profit AS net_profit
        FROM store_sales ss
        UNION ALL
        SELECT cs.cs_sold_date_sk AS date_sk,
               'catalog' AS channel,
               cs.cs_item_sk AS item_sk,
               cs.cs_net_profit AS net_profit
        FROM catalog_sales cs
        UNION ALL
        SELECT ws.ws_sold_date_sk AS date_sk,
               'web' AS channel,
               ws.ws_item_sk AS item_sk,
               ws.ws_net_profit AS net_profit
        FROM web_sales ws
    ) s
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY s.date_sk, s.channel, s.item_sk, i.i_category
),
returns_agg AS (
    SELECT r.date_sk,
           r.channel,
           r.item_sk,
           SUM(r.net_loss) AS loss
    FROM (
        SELECT sr.sr_returned_date_sk AS date_sk,
               'store' AS channel,
               sr.sr_item_sk AS item_sk,
               sr.sr_net_loss AS net_loss
        FROM store_returns sr
        UNION ALL
        SELECT cr.cr_returned_date_sk AS date_sk,
               'catalog' AS channel,
               cr.cr_item_sk AS item_sk,
               cr.cr_net_loss AS net_loss
        FROM catalog_returns cr
        UNION ALL
        SELECT wr.wr_returned_date_sk AS date_sk,
               'web' AS channel,
               wr.wr_item_sk AS item_sk,
               wr.wr_net_loss AS net_loss
        FROM web_returns wr
    ) r
    GROUP BY r.date_sk, r.channel, r.item_sk
),
final AS (
    SELECT d.d_year AS d_year,
           sa.channel,
           sa.i_category,
           SUM(sa.profit) AS total_profit,
           COALESCE(SUM(ra.loss), 0) AS total_loss,
           SUM(sa.profit) - COALESCE(SUM(ra.loss), 0) AS net_profit_adj
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.date_sk = ra.date_sk
        AND sa.channel = ra.channel
        AND sa.item_sk = ra.item_sk
    JOIN date_dim d ON sa.date_sk = d.d_date_sk
    GROUP BY d.d_year, sa.channel, sa.i_category
)
SELECT d_year,
       channel,
       i_category,
       total_profit,
       total_loss,
       net_profit_adj,
       RANK() OVER (PARTITION BY d_year, channel ORDER BY net_profit_adj DESC) AS category_rank
FROM final
ORDER BY d_year, channel, net_profit_adj DESC
FETCH FIRST 200 ROWS ONLY

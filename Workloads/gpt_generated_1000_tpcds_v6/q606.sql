WITH store_part AS (
    SELECT i.i_class AS item_class,
           'store' AS channel,
           SUM(sr.sr_net_loss) AS total_net_loss,
           CASE WHEN SUM(sr.sr_net_loss) > 100 THEN 'YES' ELSE 'NO' END AS high_loss_flag
    FROM tpcds.store_returns sr
    JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    WHERE i.i_wholesale_cost > 1.0
      AND s.s_state = 'Unknown'
    GROUP BY i.i_class
),
web_part AS (
    SELECT i.i_class AS item_class,
           'web' AS channel,
           SUM(wr.wr_net_loss) AS total_net_loss,
           CASE WHEN SUM(wr.wr_net_loss) > 100 THEN 'YES' ELSE 'NO' END AS high_loss_flag
    FROM tpcds.web_returns wr
    JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost > 1.0
    GROUP BY i.i_class
)
SELECT *
FROM store_part
UNION ALL
SELECT *
FROM web_part
ORDER BY total_net_loss DESC
LIMIT 100

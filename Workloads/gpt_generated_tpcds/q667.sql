WITH store AS (
    SELECT d.d_month_seq AS month_seq,
           i.i_category AS category,
           SUM(ss.ss_net_profit) AS total_net_profit,
           SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_month_seq, i.i_category
),
catalog AS (
    SELECT d.d_month_seq AS month_seq,
           i.i_category AS category,
           SUM(cs.cs_net_profit) AS total_net_profit,
           SUM(COALESCE(cr.cr_net_loss, 0)) AS total_net_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_month_seq, i.i_category
),
web AS (
    SELECT d.d_month_seq AS month_seq,
           i.i_category AS category,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(COALESCE(wr.wr_net_loss, 0)) AS total_net_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_month_seq, i.i_category
)
SELECT month_seq,
       category,
       SUM(total_net_profit) - SUM(total_net_loss) AS net_profit_after_returns
FROM (
    SELECT * FROM store
    UNION ALL
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM web
) combined
GROUP BY month_seq, category
ORDER BY month_seq, net_profit_after_returns DESC

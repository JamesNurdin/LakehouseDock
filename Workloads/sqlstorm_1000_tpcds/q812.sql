WITH sales AS (
    SELECT
        d.d_date AS event_date,
        i.i_item_id,
        i.i_product_name,
        s.channel,
        SUM(s.quantity) AS total_quantity,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit
    FROM (
        SELECT ss.ss_sold_date_sk AS date_sk,
               ss.ss_item_sk AS item_sk,
               ss.ss_quantity AS quantity,
               ss.ss_net_paid AS net_paid,
               ss.ss_net_profit AS net_profit,
               'store' AS channel
        FROM store_sales ss
        UNION ALL
        SELECT cs.cs_sold_date_sk,
               cs.cs_item_sk,
               cs.cs_quantity,
               cs.cs_net_paid,
               cs.cs_net_profit,
               'catalog' AS channel
        FROM catalog_sales cs
        UNION ALL
        SELECT ws.ws_sold_date_sk,
               ws.ws_item_sk,
               ws.ws_quantity,
               ws.ws_net_paid,
               ws.ws_net_profit,
               'web' AS channel
        FROM web_sales ws
    ) s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_date, i.i_item_id, i.i_product_name, s.channel
),
returns AS (
    SELECT
        d.d_date AS event_date,
        i.i_item_id,
        i.i_product_name,
        r.channel,
        SUM(r.quantity) AS total_return_quantity,
        SUM(r.return_amt) AS total_return_amount,
        SUM(r.net_loss) AS total_net_loss
    FROM (
        SELECT sr.sr_returned_date_sk AS date_sk,
               sr.sr_item_sk AS item_sk,
               sr.sr_return_quantity AS quantity,
               sr.sr_return_amt AS return_amt,
               sr.sr_net_loss AS net_loss,
               'store' AS channel
        FROM store_returns sr
        UNION ALL
        SELECT cr.cr_returned_date_sk,
               cr.cr_item_sk,
               cr.cr_return_quantity,
               cr.cr_return_amount,
               cr.cr_net_loss,
               'catalog' AS channel
        FROM catalog_returns cr
        UNION ALL
        SELECT wr.wr_returned_date_sk,
               wr.wr_item_sk,
               wr.wr_return_quantity,
               wr.wr_return_amt,
               wr.wr_net_loss,
               'web' AS channel
        FROM web_returns wr
    ) r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_date, i.i_item_id, i.i_product_name, r.channel
),
combined AS (
    SELECT
        s.event_date,
        s.i_item_id,
        s.i_product_name,
        s.channel,
        s.total_quantity,
        s.total_net_paid,
        s.total_net_profit,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_net_loss, 0) AS total_net_loss,
        s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_impact
    FROM sales s
    LEFT JOIN returns r
        ON s.event_date = r.event_date
       AND s.i_item_id = r.i_item_id
       AND s.channel = r.channel
),
daily_rank AS (
    SELECT
        event_date,
        i_item_id,
        i_product_name,
        channel,
        total_net_paid,
        total_net_profit,
        total_return_quantity,
        total_return_amount,
        total_net_loss,
        net_impact,
        ROW_NUMBER() OVER (PARTITION BY event_date ORDER BY net_impact DESC) AS rank_per_day
    FROM combined
)
SELECT
    event_date,
    i_item_id,
    i_product_name,
    channel,
    total_net_paid,
    total_net_profit,
    total_return_quantity,
    total_return_amount,
    total_net_loss,
    net_impact,
    rank_per_day,
    SUM(net_impact) OVER (PARTITION BY i_item_id ORDER BY event_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_impact
FROM daily_rank
WHERE rank_per_day <= 5
ORDER BY event_date, rank_per_day

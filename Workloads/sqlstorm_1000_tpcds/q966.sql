WITH all_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           'web'
    FROM web_sales ws
),
all_returns AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS quantity,
           cr.cr_net_loss AS net_loss,
           'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           sr.sr_return_quantity,
           sr.sr_net_loss,
           'store'
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_net_loss,
           'web'
    FROM web_returns wr
),
sales_agg AS (
    SELECT s.channel,
           d.d_year,
           d.d_quarter_seq,
           i.i_category,
           i.i_category_id,
           SUM(s.quantity) AS total_quantity_sold,
           SUM(s.net_paid) AS total_sales,
           SUM(s.net_profit) AS total_profit
    FROM all_sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY s.channel, d.d_year, d.d_quarter_seq, i.i_category, i.i_category_id
),
return_agg AS (
    SELECT r.channel,
           d.d_year,
           d.d_quarter_seq,
           i.i_category,
           i.i_category_id,
           SUM(r.quantity) AS total_quantity_returned,
           SUM(r.net_loss) AS total_return_loss
    FROM all_returns r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY r.channel, d.d_year, d.d_quarter_seq, i.i_category, i.i_category_id
)
SELECT
    sa.channel,
    sa.d_year,
    sa.d_quarter_seq,
    sa.i_category,
    sa.i_category_id,
    sa.total_quantity_sold,
    sa.total_sales,
    sa.total_profit,
    COALESCE(ra.total_quantity_returned, 0) AS total_quantity_returned,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    (sa.total_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    LAG(sa.total_profit - COALESCE(ra.total_return_loss, 0)) OVER (PARTITION BY sa.channel, sa.i_category_id ORDER BY sa.d_year, sa.d_quarter_seq) AS prior_period_profit,
    (sa.total_profit - COALESCE(ra.total_return_loss, 0)) - LAG(sa.total_profit - COALESCE(ra.total_return_loss, 0)) OVER (PARTITION BY sa.channel, sa.i_category_id ORDER BY sa.d_year, sa.d_quarter_seq) AS profit_delta,
    CASE
        WHEN LAG(sa.total_profit - COALESCE(ra.total_return_loss, 0)) OVER (PARTITION BY sa.channel, sa.i_category_id ORDER BY sa.d_year, sa.d_quarter_seq) IS NOT NULL
        THEN ROUND(100.0 * ((sa.total_profit - COALESCE(ra.total_return_loss, 0)) / LAG(sa.total_profit - COALESCE(ra.total_return_loss, 0)) OVER (PARTITION BY sa.channel, sa.i_category_id ORDER BY sa.d_year, sa.d_quarter_seq) - 1), 2)
        ELSE NULL
    END AS profit_pct_change,
    ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY (sa.total_profit - COALESCE(ra.total_return_loss, 0)) DESC) AS profit_rank_year
FROM sales_agg sa
LEFT JOIN return_agg ra
    ON sa.channel = ra.channel
   AND sa.d_year = ra.d_year
   AND sa.d_quarter_seq = ra.d_quarter_seq
   AND sa.i_category_id = ra.i_category_id
ORDER BY sa.d_year, sa.channel, net_profit_after_returns DESC
LIMIT 500

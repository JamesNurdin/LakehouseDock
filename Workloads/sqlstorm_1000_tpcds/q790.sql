WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           'web' AS channel
    FROM web_sales ws
),
returns AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS quantity,
           cr.cr_net_loss AS net_loss,
           'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk AS date_sk,
           sr.sr_item_sk AS item_sk,
           sr.sr_return_quantity AS quantity,
           sr.sr_net_loss AS net_loss,
           'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk AS date_sk,
           wr.wr_item_sk AS item_sk,
           wr.wr_return_quantity AS quantity,
           wr.wr_net_loss AS net_loss,
           'web' AS channel
    FROM web_returns wr
),
agg_sales AS (
    SELECT s.channel,
           d.d_year,
           i.i_category,
           i.i_class,
           i.i_brand,
           SUM(s.net_paid) AS total_net_paid,
           SUM(s.net_profit) AS total_net_profit,
           COUNT(*) AS sales_cnt
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY s.channel, d.d_year, i.i_category, i.i_class, i.i_brand
),
agg_returns AS (
    SELECT r.channel,
           d.d_year,
           i.i_category,
           i.i_class,
           i.i_brand,
           SUM(r.net_loss) AS total_net_loss,
           SUM(r.quantity) AS total_return_qty,
           COUNT(*) AS return_cnt
    FROM returns r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY r.channel, d.d_year, i.i_category, i.i_class, i.i_brand
),
combined AS (
    SELECT s.channel,
           s.d_year,
           s.i_category,
           s.i_class,
           s.i_brand,
           s.total_net_paid,
           s.total_net_profit,
           COALESCE(r.total_net_loss, 0) AS total_net_loss,
           COALESCE(r.total_return_qty, 0) AS total_return_qty,
           s.sales_cnt,
           COALESCE(r.return_cnt, 0) AS return_cnt,
           (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns,
           (s.total_net_paid - COALESCE(r.total_net_loss, 0)) AS net_paid_after_returns
    FROM agg_sales s
    LEFT JOIN agg_returns r
        ON s.channel = r.channel
        AND s.d_year = r.d_year
        AND s.i_category = r.i_category
        AND s.i_class = r.i_class
        AND s.i_brand = r.i_brand
),
final AS (
    SELECT channel,
           d_year,
           i_category,
           i_class,
           i_brand,
           net_profit_after_returns,
           net_paid_after_returns,
           sales_cnt,
           return_cnt,
           ROW_NUMBER() OVER (PARTITION BY channel, d_year ORDER BY net_profit_after_returns DESC) AS profit_rank
    FROM combined
)
SELECT *
FROM final
WHERE profit_rank <= 10
ORDER BY channel, d_year, profit_rank

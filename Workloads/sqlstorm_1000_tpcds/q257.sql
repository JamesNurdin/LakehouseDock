WITH sales_agg AS (
    SELECT cs.cs_item_sk AS item_sk,
           d.d_year,
           d.d_month_seq,
           SUM(cs.cs_net_paid) AS net_paid,
           SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_item_sk, d.d_year, d.d_month_seq
    UNION ALL
    SELECT ss.ss_item_sk AS item_sk,
           d.d_year,
           d.d_month_seq,
           SUM(ss.ss_net_paid) AS net_paid,
           SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_item_sk, d.d_year, d.d_month_seq
    UNION ALL
    SELECT ws.ws_item_sk AS item_sk,
           d.d_year,
           d.d_month_seq,
           SUM(ws.ws_net_paid) AS net_paid,
           SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_item_sk, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT cr.cr_item_sk AS item_sk,
           d.d_year,
           d.d_month_seq,
           SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_item_sk, d.d_year, d.d_month_seq
    UNION ALL
    SELECT sr.sr_item_sk AS item_sk,
           d.d_year,
           d.d_month_seq,
           SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_item_sk, d.d_year, d.d_month_seq
    UNION ALL
    SELECT wr.wr_item_sk AS item_sk,
           d.d_year,
           d.d_month_seq,
           SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY wr.wr_item_sk, d.d_year, d.d_month_seq
),
sales_total AS (
    SELECT item_sk,
           d_year,
           d_month_seq,
           SUM(net_paid) AS total_net_paid,
           SUM(net_profit) AS total_net_profit
    FROM sales_agg
    GROUP BY item_sk, d_year, d_month_seq
),
returns_total AS (
    SELECT item_sk,
           d_year,
           d_month_seq,
           SUM(net_loss) AS total_net_loss
    FROM returns_agg
    GROUP BY item_sk, d_year, d_month_seq
)
SELECT i.i_item_id,
       i.i_product_name,
       s.d_year,
       s.d_month_seq,
       s.total_net_paid,
       s.total_net_profit,
       COALESCE(r.total_net_loss, 0) AS total_net_loss,
       s.total_net_paid - COALESCE(r.total_net_loss, 0) AS net_revenue_after_returns
FROM sales_total s
LEFT JOIN returns_total r
    ON s.item_sk = r.item_sk
   AND s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
JOIN item i
    ON s.item_sk = i.i_item_sk
ORDER BY net_revenue_after_returns DESC
LIMIT 100

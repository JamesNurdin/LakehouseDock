WITH sales_agg AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           'catalog' AS channel,
           SUM(cs.cs_quantity) AS total_quantity,
           SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
           SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk
    UNION ALL
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           'store' AS channel,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           'web' AS channel,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
returns_agg AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           'catalog' AS channel,
           SUM(cr.cr_return_quantity) AS total_return_quantity,
           SUM(cr.cr_return_amt_inc_tax) AS total_return_amt_inc_tax,
           SUM(cr.cr_net_loss) AS total_return_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_item_sk
    UNION ALL
    SELECT sr.sr_returned_date_sk AS date_sk,
           sr.sr_item_sk AS item_sk,
           'store' AS channel,
           SUM(sr.sr_return_quantity) AS total_return_quantity,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
           SUM(sr.sr_net_loss) AS total_return_net_loss
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk
    UNION ALL
    SELECT wr.wr_returned_date_sk AS date_sk,
           wr.wr_item_sk AS item_sk,
           'web' AS channel,
           SUM(wr.wr_return_quantity) AS total_return_quantity,
           SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
           SUM(wr.wr_net_loss) AS total_return_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
),
joined AS (
    SELECT sa.date_sk,
           sa.item_sk,
           sa.channel,
           sa.total_quantity,
           sa.total_net_paid_inc_tax,
           sa.total_net_profit,
           COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
           COALESCE(ra.total_return_amt_inc_tax, 0) AS total_return_amt_inc_tax,
           COALESCE(ra.total_return_net_loss, 0) AS total_return_net_loss,
           (sa.total_net_profit - COALESCE(ra.total_return_net_loss, 0)) AS net_profit_after_returns
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
      ON sa.date_sk = ra.date_sk
     AND sa.item_sk = ra.item_sk
     AND sa.channel = ra.channel
)
SELECT d.d_year,
       i.i_category,
       i.i_class,
       j.channel,
       SUM(j.total_quantity) AS total_quantity_sold,
       SUM(j.total_return_quantity) AS total_quantity_returned,
       SUM(j.total_net_paid_inc_tax) AS total_sales_inc_tax,
       SUM(j.total_return_amt_inc_tax) AS total_returns_inc_tax,
       SUM(j.net_profit_after_returns) AS net_profit,
       ROUND(100.0 * SUM(j.total_return_quantity) / NULLIF(SUM(j.total_quantity), 0), 2) AS return_rate_percent
FROM joined j
JOIN date_dim d ON j.date_sk = d.d_date_sk
JOIN item i ON j.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2001 AND 2002
  AND i.i_category IN ('Clothing', 'Sports', 'Electronics')
GROUP BY d.d_year, i.i_category, i.i_class, j.channel
ORDER BY net_profit DESC
LIMIT 50

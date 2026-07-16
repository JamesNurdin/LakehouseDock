WITH sales AS (
   SELECT cs.cs_sold_date_sk AS date_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_net_paid AS net_paid,
          cs.cs_net_profit AS net_profit
   FROM catalog_sales cs
   UNION ALL
   SELECT ss.ss_sold_date_sk,
          ss.ss_item_sk,
          ss.ss_net_paid,
          ss.ss_net_profit
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          ws.ws_item_sk,
          ws.ws_net_paid,
          ws.ws_net_profit
   FROM web_sales ws
),
returns_agg AS (
   SELECT date_sk,
          item_sk,
          SUM(refunded_cash) AS refunded_cash,
          SUM(net_loss) AS net_loss
   FROM (
       SELECT cr.cr_returned_date_sk AS date_sk,
              cr.cr_item_sk AS item_sk,
              cr.cr_refunded_cash AS refunded_cash,
              cr.cr_net_loss AS net_loss
       FROM catalog_returns cr
       UNION ALL
       SELECT sr.sr_returned_date_sk,
              sr.sr_item_sk,
              sr.sr_refunded_cash,
              sr.sr_net_loss
       FROM store_returns sr
       UNION ALL
       SELECT wr.wr_returned_date_sk,
              wr.wr_item_sk,
              wr.wr_refunded_cash,
              wr.wr_net_loss
       FROM web_returns wr
   ) r
   GROUP BY date_sk, item_sk
)
SELECT t.d_year,
       t.i_category,
       t.net_sales,
       t.net_profit,
       t.distinct_items_sold,
       RANK() OVER (PARTITION BY t.d_year ORDER BY t.net_profit DESC) AS profit_rank
FROM (
   SELECT d.d_year,
          i.i_category,
          SUM(s.net_paid) - COALESCE(SUM(r.refunded_cash), 0) AS net_sales,
          SUM(s.net_profit) - COALESCE(SUM(r.net_loss), 0) AS net_profit,
          COUNT(DISTINCT s.item_sk) AS distinct_items_sold
   FROM sales s
   LEFT JOIN returns_agg r
     ON s.date_sk = r.date_sk AND s.item_sk = r.item_sk
   JOIN date_dim d
     ON s.date_sk = d.d_date_sk
   JOIN item i
     ON s.item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
   GROUP BY d.d_year, i.i_category
   HAVING SUM(s.net_paid) > 1000000
) t
ORDER BY t.d_year, t.net_profit DESC
LIMIT 100

WITH sales AS (
 SELECT i.i_category AS category,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS sales_profit,
        0 AS return_loss
 FROM store_sales ss
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 WHERE d.d_year = 2001
 GROUP BY i.i_category
 UNION ALL
 SELECT i.i_category,
        'catalog',
        SUM(cs.cs_net_profit),
        0
 FROM catalog_sales cs
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 WHERE d.d_year = 2001
 GROUP BY i.i_category
 UNION ALL
 SELECT i.i_category,
        'web',
        SUM(ws.ws_net_profit),
        0
 FROM web_sales ws
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 WHERE d.d_year = 2001
 GROUP BY i.i_category
),
returns AS (
 SELECT i.i_category AS category,
        'store' AS channel,
        0 AS sales_profit,
        SUM(sr.sr_net_loss) AS return_loss
 FROM store_returns sr
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 WHERE d.d_year = 2001
 GROUP BY i.i_category
 UNION ALL
 SELECT i.i_category,
        'catalog',
        0,
        SUM(cr.cr_net_loss)
 FROM catalog_returns cr
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 WHERE d.d_year = 2001
 GROUP BY i.i_category
 UNION ALL
 SELECT i.i_category,
        'web',
        0,
        SUM(wr.wr_net_loss)
 FROM web_returns wr
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 WHERE d.d_year = 2001
 GROUP BY i.i_category
),
combined AS (
 SELECT s.category,
        s.channel,
        s.sales_profit,
        COALESCE(r.return_loss, 0) AS return_loss
 FROM sales s
 LEFT JOIN returns r
   ON s.category = r.category AND s.channel = r.channel
 UNION ALL
 SELECT r.category,
        r.channel,
        COALESCE(s.sales_profit, 0) AS sales_profit,
        r.return_loss
 FROM returns r
 LEFT JOIN sales s
   ON r.category = s.category AND r.channel = s.channel
 WHERE s.category IS NULL
),
agg AS (
 SELECT category,
        SUM(sales_profit) AS total_sales_profit,
        SUM(return_loss) AS total_return_loss,
        SUM(sales_profit) - SUM(return_loss) AS net_profit
 FROM combined
 GROUP BY category
),
ranked AS (
 SELECT *,
        ROW_NUMBER() OVER (ORDER BY net_profit DESC) AS profit_rank,
        (total_sales_profit * 100.0) / SUM(total_sales_profit) OVER () AS sales_percent,
        (net_profit * 100.0) / SUM(net_profit) OVER () AS profit_percent
 FROM agg
)
SELECT category,
       total_sales_profit,
       total_return_loss,
       net_profit,
       profit_rank,
       sales_percent,
       profit_percent
FROM ranked
WHERE profit_rank <= 10
ORDER BY profit_rank

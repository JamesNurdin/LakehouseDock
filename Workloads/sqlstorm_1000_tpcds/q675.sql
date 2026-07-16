WITH sales_agg AS (
    SELECT d.d_year AS yr,
           s.s_state AS region,
           'store' AS channel,
           SUM(ss.ss_net_profit) AS sales_profit,
           SUM(COALESCE(sr.sr_net_loss, 0)) AS return_loss,
           SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_profit_adj
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
    WHERE i.i_current_price > 100
      AND d.d_year = 2001
    GROUP BY d.d_year, s.s_state

    UNION ALL

    SELECT d.d_year AS yr,
           cc.cc_state AS region,
           'catalog' AS channel,
           SUM(cs.cs_net_profit) AS sales_profit,
           SUM(COALESCE(cr.cr_net_loss, 0)) AS return_loss,
           SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) AS net_profit_adj
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND cs.cs_item_sk = cr.cr_item_sk
    WHERE i.i_current_price > 100
      AND d.d_year = 2001
    GROUP BY d.d_year, cc.cc_state

    UNION ALL

    SELECT d.d_year AS yr,
           w.web_state AS region,
           'web' AS channel,
           SUM(ws.ws_net_profit) AS sales_profit,
           SUM(COALESCE(wr.wr_net_loss, 0)) AS return_loss,
           SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0)) AS net_profit_adj
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
    WHERE i.i_current_price > 100
      AND d.d_year = 2001
    GROUP BY d.d_year, w.web_state
)
SELECT yr,
       region,
       channel,
       sales_profit,
       return_loss,
       net_profit_adj,
       DENSE_RANK() OVER (PARTITION BY yr ORDER BY net_profit_adj DESC) AS profit_rank
FROM sales_agg
WHERE region IS NOT NULL
ORDER BY yr, profit_rank
LIMIT 50

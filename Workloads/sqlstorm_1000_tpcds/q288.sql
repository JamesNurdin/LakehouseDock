WITH combined AS (
   SELECT d.d_year AS year,
          s.s_state AS state,
          i.i_category AS category,
          'store' AS channel,
          ss.ss_net_profit AS net
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   UNION ALL
   SELECT d.d_year,
          w.w_state,
          i.i_category,
          'catalog' AS channel,
          cs.cs_net_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   UNION ALL
   SELECT d.d_year,
          w2.w_state,
          i2.i_category,
          'web' AS channel,
          ws.ws_net_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
   JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   UNION ALL
   SELECT d.d_year,
          s.s_state,
          i.i_category,
          'store' AS channel,
          -sr.sr_net_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   UNION ALL
   SELECT d.d_year,
          w.w_state,
          i.i_category,
          'catalog' AS channel,
          -cr.cr_net_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   UNION ALL
   SELECT d.d_year,
          CAST(NULL AS varchar) AS state,
          i.i_category,
          'web' AS channel,
          -wr.wr_net_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
)
SELECT year,
       state,
       category,
       channel,
       SUM(net) AS net_total
FROM combined
GROUP BY year, state, category, channel
ORDER BY net_total DESC
FETCH FIRST 10 ROWS ONLY

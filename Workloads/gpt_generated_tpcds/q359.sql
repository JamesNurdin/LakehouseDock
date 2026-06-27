SELECT i_item_id,
       i_product_name,
       d_year,
       SUM(profit) AS net_profit
FROM (
   SELECT i.i_item_id,
          i.i_product_name,
          d.d_year,
          ss.ss_net_profit AS profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year = 2001

   UNION ALL

   SELECT i.i_item_id,
          i.i_product_name,
          d.d_year,
          cs.cs_net_profit AS profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2001

   UNION ALL

   SELECT i.i_item_id,
          i.i_product_name,
          d.d_year,
          ws.ws_net_profit AS profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 2001

   UNION ALL

   SELECT i.i_item_id,
          i.i_product_name,
          d.d_year,
          -sr.sr_net_loss AS profit
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001

   UNION ALL

   SELECT i.i_item_id,
          i.i_product_name,
          d.d_year,
          -cr.cr_net_loss AS profit
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001

   UNION ALL

   SELECT i.i_item_id,
          i.i_product_name,
          d.d_year,
          -wr.wr_net_loss AS profit
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
) AS agg
GROUP BY i_item_id, i_product_name, d_year
ORDER BY net_profit DESC
LIMIT 20

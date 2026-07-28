WITH filtered_items AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_manager_id,
           i.i_category
    FROM   item i
    WHERE  i.i_manager_id IN (4, 13, 27)
)
SELECT   source,
         i_item_sk,
         i_product_name,
         SUM(net_profit)                         AS total_net_profit,
         CASE WHEN SUM(net_profit) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_sign
FROM (
    SELECT   'Catalog' AS source,
             i.i_item_sk,
             i.i_product_name,
             cs.cs_net_profit                         AS net_profit
    FROM     catalog_sales cs
    JOIN     filtered_items i ON cs.cs_item_sk = i.i_item_sk
    JOIN     date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE    d.d_year = 2001
      AND    EXISTS ( SELECT 1
                      FROM   catalog_returns cr
                      WHERE  cr.cr_item_sk = cs.cs_item_sk
                        AND  cr.cr_returned_date_sk = d.d_date_sk )

    UNION ALL

    SELECT   'Web' AS source,
             i.i_item_sk,
             i.i_product_name,
             ws.ws_net_profit                         AS net_profit
    FROM     web_sales ws
    JOIN     filtered_items i ON ws.ws_item_sk = i.i_item_sk
    JOIN     date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE    d.d_year = 2001
      AND    EXISTS ( SELECT 1
                      FROM   web_returns wr
                      WHERE  wr.wr_item_sk = ws.ws_item_sk
                        AND  wr.wr_returned_date_sk = d.d_date_sk )
) sub
GROUP BY source,
         i_item_sk,
         i_product_name
HAVING SUM(net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100

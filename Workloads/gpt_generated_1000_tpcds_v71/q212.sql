/*
  Goal: Compare total net profit by item category across store sales and web sales channels, flagging whether the profit is positive or negative, and showing the overall average profit per channel using scalar subqueries. The query uses UNION ALL to combine the two channels, includes an EXISTS subquery, CASE expression, and limits the result to the top 100 categories by profit.
*/
WITH store_part AS (
    SELECT
        i.i_category AS category,
        CAST('store' AS varchar) AS sales_channel,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
        (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS overall_avg_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_quantity > 1
      AND p.p_channel_tv = 'Y'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = ss.ss_item_sk
            AND cr.cr_net_loss > 100
      )
    GROUP BY i.i_category
),
web_part AS (
    SELECT
        i.i_category AS category,
        CAST('web' AS varchar) AS sales_channel,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
        (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS overall_avg_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_quantity > 1
      AND p.p_channel_email = 'Y'
      AND ws.ws_ext_ship_cost > 1000
    GROUP BY i.i_category
)
SELECT *
FROM store_part
UNION ALL
SELECT *
FROM web_part
ORDER BY total_profit DESC
LIMIT 100

WITH unified_sales AS (
    SELECT
        'store' AS sales_channel,
        i.i_category AS i_category,
        d.d_year AS d_year,
        ss.ss_net_profit AS net_profit,
        ss.ss_customer_sk AS customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND ss.ss_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d.d_date_sk
            AND inv.inv_quantity_on_hand > 0
      )
    UNION ALL
    SELECT
        'web' AS sales_channel,
        i.i_category AS i_category,
        d.d_year AS d_year,
        ws.ws_net_profit AS net_profit,
        ws.ws_bill_customer_sk AS customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND ws.ws_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d.d_date_sk
            AND inv.inv_quantity_on_hand > 0
      )
)
SELECT
    sales_channel,
    i_category,
    d_year,
    CASE
        WHEN SUM(net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(net_profit) > 0      THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_level,
    SUM(net_profit) AS total_profit,
    COUNT(DISTINCT customer_sk) AS unique_customers,
    (SELECT AVG(net_profit) FROM unified_sales) AS avg_profit_overall
FROM unified_sales
GROUP BY sales_channel, i_category, d_year
HAVING SUM(net_profit) > (SELECT AVG(net_profit) FROM unified_sales)
ORDER BY total_profit DESC
LIMIT 100

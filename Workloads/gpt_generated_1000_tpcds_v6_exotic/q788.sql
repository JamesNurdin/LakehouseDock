/* Goal: compute combined sales and profit for items whose product names match specific patterns across web sales and store returns, enrich with average catalog return amount, and rank the top items. */
WITH ws_data AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_product_name AS product_name,
        CONCAT(i.i_brand, '-', i.i_color) AS brand_color,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        (
            SELECT AVG(cr.cr_return_amount)
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = i.i_item_sk
        ) AS avg_return_amount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_product_name, '(?i)deluxe|premium')
      AND i.i_item_id LIKE 'AAAAAAA%'
      AND ws.ws_sold_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY i.i_item_sk, i.i_product_name, i.i_brand, i.i_color
),
sr_data AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_product_name AS product_name,
        CONCAT(i.i_brand, '-', i.i_color) AS brand_color,
        SUM(sr.sr_return_amt) AS total_sales,
        SUM(sr.sr_net_loss) AS total_profit,
        (
            SELECT AVG(cr.cr_return_amount)
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = i.i_item_sk
        ) AS avg_return_amount
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE i.i_product_name LIKE '%Standard%'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_item_sk = i.i_item_sk
            AND cr2.cr_return_amount > 500
      )
    GROUP BY i.i_item_sk, i.i_product_name, i.i_brand, i.i_color
)
SELECT
    item_sk,
    product_name,
    brand_color,
    SUM(total_sales) AS combined_sales,
    SUM(total_profit) AS combined_profit,
    CASE WHEN SUM(total_profit) > 0 THEN 'Overall Profitable' ELSE 'Overall Loss' END AS overall_status,
    AVG(avg_return_amount) AS avg_return_amount_overall
FROM (
    SELECT item_sk, product_name, brand_color, total_sales, total_profit, avg_return_amount FROM ws_data
    UNION ALL
    SELECT item_sk, product_name, brand_color, total_sales, total_profit, avg_return_amount FROM sr_data
) u
GROUP BY item_sk, product_name, brand_color
ORDER BY combined_sales DESC
LIMIT 100

/*
Goal: Identify the top‑selling electronic items that were promoted, bought by good‑credit customers, and had significant sales in a recent period, while accounting for returns from both store and web channels. The query aggregates sales and returns, applies multiple filters, uses a scalar sub‑query, and ranks items within each category.
*/
WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        SUM(ws.ws_ext_sales_price)      AS total_sales,
        SUM(ws.ws_net_profit)           AS total_profit,
        COUNT(*)                        AS sales_cnt,
        AVG(ws.ws_ext_sales_price)      AS avg_sales_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE i.i_category = 'Electronics'
      AND p.p_discount_active = 'Y'
      AND cd.cd_credit_rating = 'Good'
      AND ws.ws_sold_date_sk BETWEEN 2452645 AND 2452739
    GROUP BY i.i_item_sk, i.i_product_name, i.i_category
),
returns AS (
    SELECT
        i.i_item_sk,
        SUM(sr.sr_return_amt)                AS store_return_amt,
        SUM(wr.wr_return_amt)                AS web_return_amt,
        SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss
    FROM item i
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr   ON wr.wr_item_sk   = i.i_item_sk
    GROUP BY i.i_item_sk
),
combined AS (
    SELECT
        s.i_item_sk,
        s.i_product_name,
        s.i_category,
        s.total_sales,
        s.total_profit,
        s.sales_cnt,
        s.avg_sales_price,
        r.store_return_amt,
        r.web_return_amt,
        r.total_net_loss,
        (s.total_sales - COALESCE(r.store_return_amt, 0) - COALESCE(r.web_return_amt, 0)) AS net_sales_after_returns
    FROM item_sales s
    JOIN returns r ON s.i_item_sk = r.i_item_sk
)
SELECT
    c.i_item_sk,
    c.i_product_name,
    c.i_category,
    c.total_sales,
    c.total_profit,
    c.net_sales_after_returns,
    ROW_NUMBER() OVER (PARTITION BY c.i_category ORDER BY c.net_sales_after_returns DESC) AS sales_rank,
    (
        SELECT MAX(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = c.i_item_sk
    ) AS max_sale_price
FROM combined c
WHERE c.total_profit            > 1000
  AND c.net_sales_after_returns > 0
  AND c.sales_cnt               >= 10
  AND c.total_net_loss          < 5000
ORDER BY c.net_sales_after_returns DESC
LIMIT 100

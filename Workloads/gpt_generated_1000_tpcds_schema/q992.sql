-- Goal: Identify high‑profit web‑sale items that were sold but never returned, focusing on items whose color starts with 'RED', whose product name contains a three‑letter uppercase pattern, and whose web page URL matches a .com domain. The query extracts the domain from the URL, builds a brand‑color string, classifies profit positivity, computes a running profit per item and the prior profit using window functions, and orders the results by the running profit.
WITH sold_not_returned_items AS (
    SELECT ws_item_sk
    FROM web_sales
    EXCEPT
    SELECT wr_item_sk
    FROM web_returns
)
SELECT
    ws.ws_sold_date_sk,
    i.i_item_id,
    i.i_product_name,
    concat(i.i_brand, '-', i.i_color) AS brand_color,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Positive' ELSE 'Non-positive' END AS profit_flag,
    ws.ws_quantity,
    ws.ws_net_profit,
    sum(ws.ws_net_profit) OVER (
        PARTITION BY ws.ws_item_sk
        ORDER BY ws.ws_sold_time_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_profit,
    lag(ws.ws_net_profit) OVER (
        PARTITION BY ws.ws_item_sk
        ORDER BY ws.ws_sold_time_sk
    ) AS prev_profit
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
WHERE ws.ws_item_sk IN (SELECT ws_item_sk FROM sold_not_returned_items)
  AND ws.ws_item_sk IN (
        SELECT i2.i_item_sk
        FROM item i2
        WHERE i2.i_color LIKE 'RED%'
    )
  AND regexp_like(i.i_product_name, '[A-Z]{3}')
  AND wp.wp_url LIKE 'http%://%.com%'
ORDER BY running_profit DESC
LIMIT 100

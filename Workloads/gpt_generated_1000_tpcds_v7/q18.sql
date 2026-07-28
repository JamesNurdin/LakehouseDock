WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_warehouse_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_net_profit,
        ws.ws_sold_time_sk,
        i.i_item_desc,
        i.i_product_name,
        p.p_promo_name,
        CAST(regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS INTEGER) AS promo_discount_pct,
        w.w_city,
        w.w_warehouse_id
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND i.i_item_desc LIKE 'BRAND%'
      AND NOT EXISTS (
          SELECT 1
          FROM promotion p2
          JOIN web_sales ws2 ON ws2.ws_promo_sk = p2.p_promo_sk
          WHERE ws2.ws_warehouse_sk = ws.ws_warehouse_sk
            AND p2.p_discount_active = 'N'
      )
)
SELECT
    w_city,
    w_warehouse_id,
    SUM(ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws_order_number) AS orders_cnt,
    MIN(promo_discount_pct) AS min_discount_pct,
    CASE WHEN SUM(ws_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM filtered_sales
GROUP BY w_city, w_warehouse_id
HAVING SUM(ws_net_profit) > (
    SELECT AVG(city_profit)
    FROM (
        SELECT w_city, SUM(ws_net_profit) AS city_profit
        FROM filtered_sales
        GROUP BY w_city
    ) city_totals
)
ORDER BY total_profit DESC
LIMIT 100

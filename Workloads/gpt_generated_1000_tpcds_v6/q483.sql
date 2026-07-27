WITH warehouse_sales AS (
    SELECT
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1200 AND 1203
    GROUP BY w.w_warehouse_name
),
promo_sales AS (
    SELECT
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_channel_email = 'Y'
      AND EXISTS (
          SELECT 1
          FROM warehouse w2
          WHERE w2.w_warehouse_sk = ws.ws_warehouse_sk
            AND w2.w_city = 'Chicago'
      )
    GROUP BY p.p_promo_name
)
SELECT DISTINCT
    src.source_type,
    src.name,
    src.total_profit,
    src.order_cnt
FROM (
    SELECT
        'Warehouse' AS source_type,
        ws.w_warehouse_name AS name,
        ws.total_profit,
        ws.order_cnt
    FROM warehouse_sales ws
    UNION ALL
    SELECT
        'Promotion' AS source_type,
        ps.p_promo_name AS name,
        ps.total_profit,
        ps.order_cnt
    FROM promo_sales ps
) src
ORDER BY src.total_profit DESC
LIMIT 100

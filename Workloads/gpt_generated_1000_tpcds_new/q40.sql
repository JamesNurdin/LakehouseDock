WITH cat AS (
    SELECT
        cs.cs_order_number AS order_id,
        d.d_date AS sale_date,
        p.p_promo_name AS promo_name,
        w.w_warehouse_name AS warehouse_name,
        cs.cs_net_profit AS net_profit,
        m.key AS metric,
        m.value AS metric_value
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN UNNEST(
        MAP(
            ARRAY['quantity', 'sales_price'],
            ARRAY[CAST(cs.cs_quantity AS varchar), CAST(cs.cs_sales_price AS varchar)]
        )
    ) AS m(key, value)
    WHERE d.d_year = 2001
      AND d.d_holiday = 'N'
),
web AS (
    SELECT
        ws.ws_order_number AS order_id,
        d.d_date AS sale_date,
        p.p_promo_name AS promo_name,
        w.w_warehouse_name AS warehouse_name,
        ws.ws_net_profit AS net_profit,
        m.key AS metric,
        m.value AS metric_value
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN UNNEST(
        MAP(
            ARRAY['quantity', 'sales_price'],
            ARRAY[CAST(ws.ws_quantity AS varchar), CAST(ws.ws_sales_price AS varchar)]
        )
    ) AS m(key, value)
    WHERE d.d_year = 2001
      AND d.d_holiday = 'N'
)
SELECT
    order_id,
    sale_date,
    promo_name,
    warehouse_name,
    net_profit,
    metric,
    metric_value
FROM cat
UNION ALL
SELECT
    order_id,
    sale_date,
    promo_name,
    warehouse_name,
    net_profit,
    metric,
    metric_value
FROM web
ORDER BY net_profit DESC
LIMIT 100

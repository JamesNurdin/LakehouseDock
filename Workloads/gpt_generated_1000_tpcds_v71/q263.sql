WITH catalog_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_suite_number,
        CONCAT(w.w_city, ' ', w.w_suite_number) AS warehouse_label,
        SUM(cs.cs_net_profit) AS catalog_profit,
        COUNT(*) AS catalog_orders,
        REGEXP_EXTRACT(p.p_promo_name, '(Discount)', 1) AS promo_match
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)discount')
      AND w.w_suite_number LIKE 'Suite %'
      AND SUBSTR(w.w_zip, 1, 1) = '2'
    GROUP BY
        w.w_warehouse_id,
        w.w_city,
        w.w_suite_number,
        CONCAT(w.w_city, ' ', w.w_suite_number),
        REGEXP_EXTRACT(p.p_promo_name, '(Discount)', 1)
),
web_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_suite_number,
        CONCAT(w.w_city, ' ', w.w_suite_number) AS warehouse_label,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(*) AS web_orders,
        REGEXP_EXTRACT(p.p_promo_name, '(Discount)', 1) AS promo_match
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)discount')
      AND w.w_suite_number LIKE 'Suite %'
      AND SUBSTR(w.w_zip, 1, 1) = '2'
    GROUP BY
        w.w_warehouse_id,
        w.w_city,
        w.w_suite_number,
        CONCAT(w.w_city, ' ', w.w_suite_number),
        REGEXP_EXTRACT(p.p_promo_name, '(Discount)', 1)
),
combined AS (
    SELECT
        w_warehouse_id,
        warehouse_label,
        catalog_profit AS profit,
        catalog_orders AS orders
    FROM catalog_agg
    UNION ALL
    SELECT
        w_warehouse_id,
        warehouse_label,
        web_profit AS profit,
        web_orders AS orders
    FROM web_agg
)
SELECT
    c.w_warehouse_id,
    c.warehouse_label,
    SUM(c.profit) AS total_profit,
    SUM(c.orders) AS total_orders,
    CASE WHEN SUM(c.orders) = 0 THEN NULL ELSE SUM(c.profit) / SUM(c.orders) END AS avg_profit_per_order,
    (SELECT AVG(cs.cs_net_profit) FROM catalog_sales cs) AS avg_catalog_profit
FROM combined c
GROUP BY c.w_warehouse_id, c.warehouse_label
ORDER BY total_profit DESC
LIMIT 10

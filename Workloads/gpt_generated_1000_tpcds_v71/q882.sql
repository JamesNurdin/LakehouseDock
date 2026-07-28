WITH catalog_agg AS (
    SELECT
        cs.cs_promo_sk,
        SUM(cs.cs_net_paid_inc_ship) AS cat_sales_net,
        COUNT(*) AS cat_orders,
        AVG(cs.cs_quantity) AS cat_avg_qty
    FROM catalog_sales cs
    WHERE cs.cs_ship_addr_sk IN (572777, 5167051)
      AND cs.cs_net_paid_inc_tax > 5000
      AND cs.cs_quantity BETWEEN 1 AND 10
      AND cs.cs_promo_sk IS NOT NULL
    GROUP BY cs.cs_promo_sk
),
web_agg AS (
    SELECT
        ws.ws_promo_sk,
        SUM(ws.ws_net_paid_inc_ship_tax) AS web_sales_net,
        COUNT(*) AS web_orders,
        AVG(ws.ws_quantity) AS web_avg_qty
    FROM web_sales ws
    WHERE ws.ws_wholesale_cost > 30
      AND ws.ws_net_paid_inc_ship_tax < 8000
      AND ws.ws_quantity BETWEEN 1 AND 20
      AND ws.ws_promo_sk IS NOT NULL
    GROUP BY ws.ws_promo_sk
),
combined AS (
    SELECT cs_promo_sk AS promo_sk, cat_sales_net AS sales_net, cat_orders AS orders, cat_avg_qty AS avg_qty, 'catalog' AS source
    FROM catalog_agg
    UNION ALL
    SELECT ws_promo_sk AS promo_sk, web_sales_net, web_orders, web_avg_qty, 'web' AS source
    FROM web_agg
)
SELECT
    p.p_promo_id,
    c.source,
    c.sales_net,
    c.orders,
    c.avg_qty,
    CASE
        WHEN c.sales_net > 10000 THEN 'High'
        WHEN c.sales_net > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    RANK() OVER (PARTITION BY c.source ORDER BY c.sales_net DESC) AS sales_rank,
    (
        SELECT COUNT(*)
        FROM promotion p2
        WHERE p2.p_channel_email = p.p_channel_email
    ) AS same_email_promo_cnt
FROM combined c
JOIN promotion p ON c.promo_sk = p.p_promo_sk
WHERE p.p_channel_event = 'N'
  AND p.p_discount_active = 'Y'
  AND p.p_promo_name IS NOT NULL
  AND p.p_start_date_sk >= 2450000
  AND p.p_end_date_sk <= 2452000
  AND (p.p_channel_tv = 'N' OR p.p_channel_radio = 'N')
ORDER BY c.sales_net DESC
LIMIT 100

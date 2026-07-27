WITH sales_cte AS (
    SELECT
        'sale' AS activity,
        cs.cs_warehouse_sk AS entity_id,
        cs.cs_net_paid AS amount,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'high' ELSE 'medium' END AS category
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_net_paid > 500
),
returns_cte AS (
    SELECT
        'return' AS activity,
        sr.sr_addr_sk AS entity_id,
        sr.sr_refunded_cash AS amount,
        CASE WHEN sr.sr_fee > 50 THEN 'high_fee' ELSE 'low_fee' END AS category
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd2 ON sr.sr_cdemo_sk = cd2.cd_demo_sk
    WHERE sr.sr_refunded_cash > 100
)
SELECT activity, entity_id, amount, category
FROM sales_cte
UNION ALL
SELECT activity, entity_id, amount, category
FROM returns_cte
ORDER BY amount DESC
LIMIT 100

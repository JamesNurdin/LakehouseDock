WITH
unified_sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        'store' AS channel,
        CAST(NULL AS integer) AS call_center_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity,
        'catalog' AS channel,
        cs.cs_call_center_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_quantity,
        'web' AS channel,
        CAST(NULL AS integer) AS call_center_sk
    FROM web_sales ws
),
aggregated_sales AS (
    SELECT
        us.customer_sk,
        us.channel,
        SUM(us.net_profit) AS total_net_profit,
        SUM(us.net_paid) AS total_net_paid,
        SUM(us.quantity) AS total_quantity,
        COUNT(*) AS transaction_count,
        MAX(us.sold_date_sk) AS most_recent_date_sk,
        MAX(us.call_center_sk) AS call_center_sk
    FROM unified_sales us
    GROUP BY us.customer_sk, us.channel
),
customer_ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY a.channel ORDER BY a.total_net_profit DESC) AS rank_in_channel,
        SUM(a.total_net_profit) OVER (PARTITION BY a.channel) AS channel_total_net_profit,
        CASE
            WHEN a.total_net_profit > 0 THEN 'positive'
            WHEN a.total_net_profit < 0 THEN 'negative'
            ELSE 'zero'
        END AS profit_status,
        (SELECT COALESCE(SUM(other.total_net_profit), 0)
         FROM aggregated_sales other
         WHERE other.customer_sk = a.customer_sk
           AND other.channel <> a.channel) AS cross_channel_net_profit,
        a.total_net_profit - (SELECT AVG(total_net_profit) FROM aggregated_sales) AS profit_vs_average
    FROM aggregated_sales a
),
inventory_latest AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk
    FROM inventory inv
    WHERE inv.inv_date_sk = (
        SELECT MAX(inner_inv.inv_date_sk)
        FROM inventory inner_inv
        WHERE inner_inv.inv_item_sk = inv.inv_item_sk
    )
),
item_profit AS (
    SELECT
        s.item_sk,
        SUM(s.net_profit) AS total_item_net_profit,
        SUM(s.quantity) AS total_item_quantity,
        MAX(s.sold_date_sk) AS most_recent_sold_date_sk
    FROM unified_sales s
    GROUP BY s.item_sk
    HAVING SUM(s.net_profit) < 0
),
item_negative AS (
    SELECT
        ip.item_sk,
        ip.total_item_net_profit,
        ip.total_item_quantity,
        ip.most_recent_sold_date_sk,
        il.inv_quantity_on_hand,
        il.inv_date_sk
    FROM item_profit ip
    LEFT JOIN inventory_latest il ON il.inv_item_sk = ip.item_sk
)
SELECT
    'customer' AS entity_type,
    c.c_customer_id AS entity_id,
    CONCAT(c.c_last_name, ', ', c.c_first_name) AS entity_name,
    cr.channel,
    cr.total_net_profit,
    cr.rank_in_channel,
    cr.profit_status,
    d.d_date AS most_recent_purchase_date,
    CONCAT('CC:', COALESCE(cc.cc_name, 'N/A'), ' VIP:', CASE WHEN cr.profit_status = 'positive' AND cc.cc_name IS NOT NULL THEN 'YES' ELSE 'NO' END, ' CrossProfit:', CAST(cr.cross_channel_net_profit AS varchar)) AS extra_info,
    cr.channel_total_net_profit,
    cr.profit_vs_average
FROM customer_ranked cr
JOIN customer c ON c.c_customer_sk = cr.customer_sk
LEFT JOIN date_dim d ON d.d_date_sk = cr.most_recent_date_sk
LEFT JOIN call_center cc ON cc.cc_call_center_sk = cr.call_center_sk
WHERE cr.rank_in_channel <= 10

UNION ALL

SELECT
    'item' AS entity_type,
    i.i_item_id AS entity_id,
    i.i_product_name AS entity_name,
    NULL AS channel,
    ipn.total_item_net_profit AS total_net_profit,
    NULL AS rank_in_channel,
    CASE
        WHEN ipn.total_item_net_profit > 0 THEN 'positive'
        WHEN ipn.total_item_net_profit < 0 THEN 'negative'
        ELSE 'zero'
    END AS profit_status,
    NULL AS most_recent_purchase_date,
    CONCAT('Category:', i.i_category, ' Brand:', i.i_brand, ' InvQty:', COALESCE(CAST(ipn.inv_quantity_on_hand AS varchar), '0')) AS extra_info,
    NULL AS channel_total_net_profit,
    NULL AS profit_vs_average
FROM item_negative ipn
JOIN item i ON i.i_item_sk = ipn.item_sk

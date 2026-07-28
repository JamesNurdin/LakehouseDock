WITH catalog_part AS (
    SELECT
        ca.ca_state AS state,
        i.i_item_id AS item_id,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS txn_count
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE i.i_wholesale_cost > 5
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
    GROUP BY ca.ca_state, i.i_item_id, p.p_promo_name
),
store_part AS (
    SELECT
        ca.ca_state AS state,
        i.i_item_id AS item_id,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE i.i_wholesale_cost > 5
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
    GROUP BY ca.ca_state, i.i_item_id, p.p_promo_name
)
SELECT DISTINCT
    state,
    item_id,
    promo_name,
    total_net_paid,
    txn_count,
    source
FROM (
    SELECT state, item_id, promo_name, total_net_paid, txn_count, 'catalog' AS source
    FROM catalog_part
    UNION ALL
    SELECT state, item_id, promo_name, total_net_paid, txn_count, 'store' AS source
    FROM store_part
) combined
ORDER BY total_net_paid DESC
LIMIT 100

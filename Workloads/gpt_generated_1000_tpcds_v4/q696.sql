WITH store_agg AS (
    SELECT i.i_item_id,
           i.i_product_name,
           SUM(ss.ss_net_paid) AS store_net_paid,
           COUNT(*) AS store_transactions
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
    GROUP BY i.i_item_id, i.i_product_name
),
catalog_agg AS (
    SELECT i.i_item_id,
           i.i_product_name,
           SUM(cs.cs_net_paid_inc_tax) AS catalog_net_paid_inc_tax,
           COUNT(*) AS catalog_transactions
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT sa.i_item_id,
       sa.i_product_name,
       sa.store_net_paid AS total_amount,
       'store' AS channel,
       sa.store_transactions AS txn_count
FROM store_agg sa
WHERE sa.store_net_paid > (SELECT AVG(store_net_paid) FROM store_agg)
UNION ALL
SELECT ca.i_item_id,
       ca.i_product_name,
       ca.catalog_net_paid_inc_tax AS total_amount,
       'catalog' AS channel,
       ca.catalog_transactions AS txn_count
FROM catalog_agg ca
WHERE ca.catalog_net_paid_inc_tax > (SELECT AVG(catalog_net_paid_inc_tax) FROM catalog_agg)
ORDER BY total_amount DESC
LIMIT 100

WITH distinct_promos AS (
    SELECT DISTINCT p.p_promo_sk
    FROM promotion p
    WHERE p.p_channel_demo = 'N'
      AND p.p_response_target = 1
),
store_agg AS (
    SELECT
        s.ss_promo_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS store_txn_count,
        SUM(s.ss_net_paid_inc_tax) AS store_total_net_paid,
        AVG(s.ss_ext_discount_amt) AS store_avg_discount,
        MIN(s.ss_net_profit) AS store_min_profit,
        MAX(s.ss_net_profit) AS store_max_profit
    FROM store_sales s
    JOIN distinct_promos dp
        ON s.ss_promo_sk = dp.p_promo_sk
    WHERE s.ss_net_paid_inc_tax > 1500
      AND s.ss_quantity > 1
      AND s.ss_ext_list_price >= 100
    GROUP BY s.ss_promo_sk
),
catalog_agg AS (
    SELECT
        c.cs_promo_sk,
        COUNT(DISTINCT c.cs_order_number) AS catalog_txn_count,
        SUM(c.cs_net_paid_inc_tax) AS catalog_total_net_paid,
        AVG(c.cs_ext_discount_amt) AS catalog_avg_discount,
        MIN(c.cs_net_profit) AS catalog_min_profit,
        MAX(c.cs_net_profit) AS catalog_max_profit
    FROM catalog_sales c
    JOIN distinct_promos dp
        ON c.cs_promo_sk = dp.p_promo_sk
    WHERE c.cs_ext_ship_cost > 500
      AND c.cs_quantity > 0
      AND c.cs_ext_sales_price >= 200
    GROUP BY c.cs_promo_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    sa.store_txn_count,
    ca.catalog_txn_count,
    sa.store_total_net_paid + ca.catalog_total_net_paid AS total_net_paid,
    (sa.store_avg_discount + ca.catalog_avg_discount) / 2 AS avg_discount,
    LEAST(sa.store_min_profit, ca.catalog_min_profit) AS overall_min_profit,
    GREATEST(sa.store_max_profit, ca.catalog_max_profit) AS overall_max_profit
FROM promotion p
JOIN distinct_promos dp
    ON p.p_promo_sk = dp.p_promo_sk
JOIN store_agg sa
    ON p.p_promo_sk = sa.ss_promo_sk
JOIN catalog_agg ca
    ON p.p_promo_sk = ca.cs_promo_sk
WHERE p.p_channel_tv = 'Y'
  AND p.p_discount_active = 'Y'
  AND sa.store_total_net_paid > 5000
  AND ca.catalog_total_net_paid > 2000
ORDER BY total_net_paid DESC
LIMIT 100

WITH active_promotions AS (
    SELECT p_promo_sk, p_cost
    FROM promotion
    WHERE p_discount_active = 'Y'
      AND p_channel_email = 'Y'
)
SELECT combined.c_customer_id,
       combined.sales_channel,
       combined.total_net_profit,
       combined.transaction_cnt,
       combined.avg_active_promo_cost
FROM (
    SELECT c.c_customer_id,
           'catalog' AS sales_channel,
           SUM(cs.cs_net_profit) AS total_net_profit,
           COUNT(*) AS transaction_cnt,
           (SELECT AVG(p_cost) FROM active_promotions) AS avg_active_promo_cost
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_promo_sk IN (SELECT p_promo_sk FROM active_promotions)
      AND cs.cs_net_paid_inc_ship_tax > 5000
    GROUP BY c.c_customer_id
    HAVING SUM(cs.cs_net_profit) > 1000

    UNION ALL

    SELECT c.c_customer_id,
           'store' AS sales_channel,
           SUM(ss.ss_net_profit) AS total_net_profit,
           COUNT(*) AS transaction_cnt,
           (SELECT AVG(p_cost) FROM active_promotions) AS avg_active_promo_cost
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_sk IN (SELECT p_promo_sk FROM active_promotions)
      AND ss.ss_net_paid_inc_tax > 5000
    GROUP BY c.c_customer_id
    HAVING SUM(ss.ss_net_profit) > 1000
) AS combined
ORDER BY combined.total_net_profit DESC
LIMIT 100

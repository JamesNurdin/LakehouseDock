SELECT
    p.p_promo_id,
    p.p_promo_name,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS sales_cnt,
    (SELECT AVG(ss2.ss_net_paid_inc_tax) FROM tpcds.store_sales ss2) AS overall_avg_net_paid
FROM tpcds.promotion p
JOIN tpcds.store_sales ss
  ON ss.ss_promo_sk = p.p_promo_sk
WHERE p.p_channel_press = 'Y'
  AND p.p_end_date_sk BETWEEN 2450400 AND 2450500
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_sales ss3
        WHERE ss3.ss_item_sk = p.p_item_sk
          AND ss3.ss_net_profit > 0
      )
GROUP BY p.p_promo_id, p.p_promo_name

UNION ALL

SELECT
    p.p_promo_id,
    p.p_promo_name,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS sales_cnt,
    (SELECT AVG(ss2.ss_net_paid_inc_tax) FROM tpcds.store_sales ss2) AS overall_avg_net_paid
FROM tpcds.promotion p
JOIN tpcds.store_sales ss
  ON ss.ss_promo_sk = p.p_promo_sk
WHERE p.p_channel_email = 'Y'
  AND p.p_end_date_sk BETWEEN 2450600 AND 2450700
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_sales ss3
        WHERE ss3.ss_item_sk = p.p_item_sk
          AND ss3.ss_net_profit > 0
      )
GROUP BY p.p_promo_id, p.p_promo_name

ORDER BY total_net_paid DESC
LIMIT 100

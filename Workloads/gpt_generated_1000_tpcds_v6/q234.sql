SELECT
    p.p_promo_id,
    p.p_promo_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(ss.ss_net_paid) / (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS revenue_vs_avg_ratio
FROM store_sales ss
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450500
GROUP BY p.p_promo_id, p.p_promo_name
HAVING SUM(ss.ss_net_paid) > 10000

UNION ALL

SELECT
    p.p_promo_id,
    p.p_promo_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(ss.ss_net_paid) / (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS revenue_vs_avg_ratio
FROM store_sales ss
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE ss.ss_sold_date_sk BETWEEN 2449000 AND 2449500
  AND c.c_email_address LIKE '%@org'
GROUP BY p.p_promo_id, p.p_promo_name
HAVING SUM(ss.ss_net_paid) > 5000

ORDER BY total_net_paid DESC
LIMIT 100

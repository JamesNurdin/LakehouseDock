WITH overall_avg AS (
    SELECT AVG(net_paid) AS avg_net_paid
    FROM (
        SELECT ss_net_paid AS net_paid FROM store_sales
        UNION ALL
        SELECT ws_net_paid FROM web_sales
    ) AS u
)

SELECT
    s.s_store_id AS category,
    p.p_promo_name AS promo_name,
    t.t_hour AS hour,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_net_paid) AS avg_net_paid,
    oa.avg_net_paid AS overall_avg_net_paid
FROM store_sales ss
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
CROSS JOIN overall_avg oa
WHERE cd.cd_marital_status = 'M'
  AND s.s_state = 'CA'
  AND t.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY s.s_store_id, p.p_promo_name, t.t_hour, oa.avg_net_paid
HAVING SUM(ss.ss_net_paid) > 10000

UNION ALL

SELECT
    sm.sm_type AS category,
    p.p_promo_name AS promo_name,
    t.t_hour AS hour,
    COUNT(*) AS sales_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_net_paid) AS avg_net_paid,
    oa.avg_net_paid AS overall_avg_net_paid
FROM web_sales ws
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
CROSS JOIN overall_avg oa
WHERE cd_bill.cd_gender = 'F'
  AND sm.sm_carrier = 'UPS'
  AND t.t_hour BETWEEN 12 AND 20
GROUP BY sm.sm_type, p.p_promo_name, t.t_hour, oa.avg_net_paid
HAVING COUNT(*) >= 50
ORDER BY total_net_paid DESC
LIMIT 100

WITH ws_agg AS (
    SELECT
        ws.ws_ship_mode_sk,
        ws.ws_bill_cdemo_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ws.ws_ship_mode_sk IN (
          SELECT sm.sm_ship_mode_sk
          FROM ship_mode sm
          WHERE sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
      )
      AND ws.ws_bill_cdemo_sk IN (
          SELECT cd.cd_demo_sk
          FROM customer_demographics cd
          WHERE cd.cd_dep_count >= 2
      )
    GROUP BY ws.ws_ship_mode_sk, ws.ws_bill_cdemo_sk
),
union_agg AS (
    SELECT
        cr.cr_ship_mode_sk AS ship_mode_sk,
        cr.cr_refunded_cdemo_sk AS demo_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450050
    GROUP BY cr.cr_ship_mode_sk, cr.cr_refunded_cdemo_sk

    UNION ALL

    SELECT
        cr.cr_ship_mode_sk,
        cr.cr_returning_cdemo_sk,
        SUM(cr.cr_return_amount),
        COUNT(*)
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
      AND cr.cr_returned_date_sk BETWEEN 2450051 AND 2450100
    GROUP BY cr.cr_ship_mode_sk, cr.cr_returning_cdemo_sk
)
SELECT
    sm.sm_ship_mode_id,
    cd.cd_gender,
    SUM(u.total_return_amount) AS sum_return_amount,
    AVG(u.total_return_amount) AS avg_return_amount,
    COUNT(*) AS num_groups,
    COALESCE(SUM(ws.total_net_paid), 0) AS sum_net_paid
FROM union_agg u
JOIN ship_mode sm ON u.ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON u.demo_sk = cd.cd_demo_sk
LEFT JOIN ws_agg ws ON ws.ws_ship_mode_sk = u.ship_mode_sk
    AND ws.ws_bill_cdemo_sk = u.demo_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws2
    WHERE ws2.ws_ship_mode_sk = u.ship_mode_sk
      AND ws2.ws_bill_cdemo_sk = u.demo_sk
      AND ws2.ws_net_paid > 1000
      AND ws2.ws_sold_date_sk BETWEEN 2450000 AND 2450200
)
  AND sm.sm_contract = 'UaAJjKDnL4gTOqbpj'
  AND cd.cd_dep_employed_count >= 3
  AND sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
GROUP BY sm.sm_ship_mode_id, cd.cd_gender
ORDER BY sum_return_amount DESC
LIMIT 100

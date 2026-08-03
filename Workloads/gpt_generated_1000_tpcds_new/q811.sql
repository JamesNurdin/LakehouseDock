WITH sampled_ws AS (
   SELECT ws_sold_date_sk,
          ws_ship_mode_sk,
          ws_net_paid_inc_ship,
          ws_bill_cdemo_sk
   FROM web_sales TABLESAMPLE BERNOULLI (5)
   WHERE ws_sold_date_sk >= 2451000
),
date_filtered AS (
   SELECT d_date_sk,
          d_date,
          d_year
   FROM date_dim
   WHERE d_year = 2002
),
union_set AS (
   SELECT d.d_date_sk,
          d.d_date,
          sm.sm_carrier AS ship_mode,
          cr.cr_return_amount AS total_amount,
          cd.cd_gender AS gender
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE cr.cr_return_amount > 100
   UNION
   SELECT d.d_date_sk,
          d.d_date,
          sm.sm_carrier AS ship_mode,
          ws.ws_net_paid_inc_ship AS total_amount,
          cd.cd_gender AS gender
   FROM sampled_ws ws
   JOIN date_filtered d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE ws.ws_net_paid_inc_ship > 500
     AND EXISTS (
         SELECT 1
         FROM ship_mode sm2
         WHERE sm2.sm_carrier = sm.sm_carrier
           AND sm2.sm_contract IS NOT NULL
     )
),
combined AS (
   SELECT *
   FROM union_set
   EXCEPT
   SELECT d.d_date_sk,
          d.d_date,
          CAST(NULL AS varchar) AS ship_mode,
          sr.sr_return_amt AS total_amount,
          cd.cd_gender AS gender
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
)
SELECT c.d_date,
       c.ship_mode,
       c.total_amount,
       c.gender,
       lc.return_cnt
FROM combined c
CROSS JOIN LATERAL (
   SELECT COUNT(*) AS return_cnt
   FROM catalog_returns cr
   WHERE cr.cr_returned_date_sk = c.d_date_sk
) lc
ORDER BY c.total_amount DESC
LIMIT 100

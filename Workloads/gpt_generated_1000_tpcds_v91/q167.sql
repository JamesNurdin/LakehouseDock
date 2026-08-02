WITH filtered_returns AS (
   SELECT
       cc.cc_division_name,
       w.w_warehouse_id,
       r.r_reason_id,
       cr.cr_return_amount,
       cr.cr_net_loss,
       ca_ref.ca_zip AS ca_zip,
       hd_ref.hd_income_band_sk,
       max_ret.max_return_amount
   FROM catalog_returns cr
   INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   INNER JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   INNER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   INNER JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   INNER JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   CROSS JOIN LATERAL (
       SELECT MAX(cr2.cr_return_amount) AS max_return_amount
       FROM catalog_returns cr2
       WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
   ) AS max_ret
   WHERE r.r_reason_id = 'AAAAAAAACBAAAAAA'
     AND w.w_state = 'CA'
     AND cc.cc_division_name = 'able'
     AND ca_ref.ca_zip LIKE '90%'
     AND hd_ref.hd_income_band_sk = 5
     AND cr.cr_return_amount > 100
),
filtered_returns_2 AS (
   SELECT
       cc.cc_division_name,
       w.w_warehouse_id,
       r.r_reason_id,
       cr.cr_return_amount,
       cr.cr_net_loss,
       ca_ref.ca_zip AS ca_zip,
       hd_ref.hd_income_band_sk,
       max_ret.max_return_amount
   FROM catalog_returns cr
   INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   INNER JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   INNER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   INNER JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   INNER JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   CROSS JOIN LATERAL (
       SELECT MAX(cr2.cr_return_amount) AS max_return_amount
       FROM catalog_returns cr2
       WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
   ) AS max_ret
   WHERE r.r_reason_id = 'AAAAAAAADBAAAAAA'
     AND w.w_state = 'CA'
     AND cc.cc_division_name = 'able'
     AND ca_ref.ca_zip LIKE '90%'
     AND hd_ref.hd_income_band_sk = 5
     AND cr.cr_return_amount > 100
),
unioned AS (
   SELECT
       cc_division_name,
       w_warehouse_id,
       r_reason_id,
       cr_return_amount,
       cr_net_loss,
       ca_zip,
       hd_income_band_sk,
       max_return_amount
   FROM filtered_returns
   UNION DISTINCT
   SELECT
       cc_division_name,
       w_warehouse_id,
       r_reason_id,
       cr_return_amount,
       cr_net_loss,
       ca_zip,
       hd_income_band_sk,
       max_return_amount
   FROM filtered_returns_2
),
aggregated AS (
   SELECT
       cc_division_name,
       w_warehouse_id,
       SUM(cr_return_amount) AS total_return_amount,
       SUM(cr_net_loss) AS total_net_loss,
       AVG(max_return_amount) AS avg_max_return_amount
   FROM unioned
   GROUP BY ROLLUP (cc_division_name, w_warehouse_id)
)
SELECT
   cc_division_name,
   w_warehouse_id,
   total_return_amount,
   total_net_loss,
   avg_max_return_amount,
   RANK() OVER (PARTITION BY cc_division_name ORDER BY total_net_loss DESC) AS net_loss_rank,
   (SELECT COUNT(DISTINCT r_sub.r_reason_id)
    FROM reason r_sub
    WHERE r_sub.r_reason_desc LIKE '%price%') AS price_related_reason_count
FROM aggregated
WHERE total_return_amount IS NOT NULL
ORDER BY cc_division_name, w_warehouse_id

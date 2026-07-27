WITH detailed AS (
   SELECT
     cr.cr_refunded_customer_sk AS customer_sk,
     cr.cr_net_loss AS catalog_net_loss,
     cr.cr_return_quantity AS catalog_qty,
     cr.cr_order_number AS catalog_order_number,
     cr.cr_call_center_sk,
     c.c_customer_id,
     c.c_birth_month,
     c.c_birth_country,
     cd.cd_education_status,
     hd.hd_demo_sk,
     hd.hd_income_band_sk,
     ib.ib_income_band_sk,
     ib.ib_lower_bound,
     ib.ib_upper_bound,
     cc.cc_state,
     cc.cc_gmt_offset,
     wr.wr_net_loss AS web_net_loss,
     wr.wr_return_quantity AS web_qty,
     wr.wr_order_number AS web_order_number
   FROM tpcds.catalog_returns cr
   JOIN tpcds.customer c
     ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN tpcds.customer_demographics cd
     ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.household_demographics hd
     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN tpcds.call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN tpcds.web_returns wr
     ON wr.wr_refunded_customer_sk = c.c_customer_sk
)
SELECT DISTINCT
   customer_sk,
   c_customer_id,
   c_birth_month,
   c_birth_country,
   cd_education_status,
   ib_lower_bound,
   ib_upper_bound,
   cc_state,
   COALESCE(SUM(catalog_net_loss), 0) + COALESCE(SUM(web_net_loss), 0) AS total_net_loss,
   COUNT(DISTINCT catalog_order_number) AS catalog_orders,
   COUNT(DISTINCT web_order_number) AS web_orders,
   RANK() OVER (
       PARTITION BY ib_income_band_sk
       ORDER BY COALESCE(SUM(catalog_net_loss), 0) + COALESCE(SUM(web_net_loss), 0) DESC
   ) AS loss_rank,
   CASE
       WHEN COALESCE(SUM(catalog_net_loss), 0) + COALESCE(SUM(web_net_loss), 0) > 20000 THEN 'HIGH'
       WHEN COALESCE(SUM(catalog_net_loss), 0) + COALESCE(SUM(web_net_loss), 0) > 0    THEN 'MEDIUM'
       ELSE 'LOW'
   END AS loss_category,
   (
       SELECT AVG(cr2.cr_net_loss)
       FROM tpcds.catalog_returns cr2
       WHERE cr2.cr_refunded_hdemo_sk = hd_demo_sk
   ) AS avg_net_loss_by_household_demo
FROM detailed
WHERE c_birth_month IN (1, 4, 11)
  AND c_birth_country = 'FIJI'
  AND cd_education_status = 'Primary'
  AND ib_upper_bound >= 90000
  AND cc_gmt_offset > -5
GROUP BY
   customer_sk,
   c_customer_id,
   c_birth_month,
   c_birth_country,
   cd_education_status,
   ib_lower_bound,
   ib_upper_bound,
   cc_state,
   ib_income_band_sk,
   hd_demo_sk
ORDER BY total_net_loss DESC
LIMIT 100

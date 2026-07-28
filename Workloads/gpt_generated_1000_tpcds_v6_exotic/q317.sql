WITH
  returns_enriched AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_net_loss,
      r.r_reason_desc,
      c.c_customer_id,
      cd.cd_gender,
      cd.cd_marital_status,
      hd.hd_income_band_sk,
      td.t_hour,
      CONCAT(r.r_reason_desc, ' - ', c.c_customer_id) AS reason_customer_concat
    FROM catalog_returns cr
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td
      ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|broken|does not work')
      AND c.c_last_name LIKE 'S%'
  ),
  aggregated AS (
    SELECT
      re.cd_gender,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      COUNT(*) AS num_returns,
      SUM(re.cr_net_loss) AS total_net_loss,
      AVG(re.cr_return_amount) AS avg_return_amount
    FROM returns_enriched re
    JOIN income_band ib
      ON re.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY re.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
  )
SELECT
  a.cd_gender,
  a.ib_lower_bound,
  a.ib_upper_bound,
  a.num_returns,
  a.total_net_loss,
  a.avg_return_amount,
  ROW_NUMBER() OVER (PARTITION BY a.cd_gender ORDER BY a.total_net_loss DESC) AS gender_loss_rank,
  (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     JOIN reason r2 ON cr2.cr_reason_sk = r2.r_reason_sk
    WHERE regexp_like(r2.r_reason_desc, '(?i)damage')) AS avg_damage_return_amount
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100

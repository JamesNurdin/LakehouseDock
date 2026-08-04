WITH
  store_loss AS (
    SELECT
      ss.ss_store_sk AS store_sk,
      r.r_reason_desc AS reason_desc,
      SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN store_sales ss
      ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY ss.ss_store_sk, r.r_reason_desc
  ),
  callcenter_loss AS (
    SELECT
      cc.cc_call_center_id AS call_center_id,
      r.r_reason_desc AS reason_desc,
      SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY cc.cc_call_center_id, r.r_reason_desc
  ),
  genders AS (
    SELECT DISTINCT cd_gender AS gender
    FROM customer_demographics
    WHERE cd_gender IS NOT NULL
    LIMIT 5
  )
SELECT
  CAST(store_sk AS varchar) AS entity_id,
  'store' AS entity_type,
  reason_desc,
  total_net_loss,
  gender
FROM store_loss
CROSS JOIN genders
UNION
SELECT
  CAST(call_center_id AS varchar) AS entity_id,
  'call_center' AS entity_type,
  reason_desc,
  total_net_loss,
  gender
FROM callcenter_loss
CROSS JOIN genders
ORDER BY total_net_loss DESC
LIMIT 100

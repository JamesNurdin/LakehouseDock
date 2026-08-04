WITH
  store_side AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_fee,
      sr.sr_net_loss,
      sr.sr_customer_sk,
      sr.sr_cdemo_sk,
      sr.sr_addr_sk,
      sr.sr_reason_sk,
      cd.cd_gender,
      ca.ca_state,
      r.r_reason_desc
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  ),
  catalog_side AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_fee,
      cr.cr_net_loss,
      cr.cr_refunded_cdemo_sk,
      cr.cr_refunded_addr_sk,
      cr.cr_reason_sk,
      cr.cr_ship_mode_sk,
      cd.cd_gender AS cd_gender_ref,
      ca.ca_state AS ca_state_ref,
      r.r_reason_desc AS r_reason_desc_ref,
      sm.sm_contract,
      sm.sm_ship_mode_id
    FROM catalog_returns cr
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  ),
  combined AS (
    SELECT
      COALESCE(s.r_reason_desc, c.r_reason_desc_ref) AS reason_desc,
      COALESCE(c.sm_contract, 'UNKNOWN') AS ship_contract,
      s.sr_net_loss AS store_net_loss,
      c.cr_net_loss AS catalog_net_loss,
      s.sr_customer_sk,
      w.wr_refunded_customer_sk,
      s.sr_fee,
      c.cr_return_amount,
      c.sm_contract,
      w.wr_return_amt_inc_tax
    FROM store_side s
    FULL OUTER JOIN catalog_side c ON s.sr_reason_sk = c.cr_reason_sk
    LEFT JOIN web_returns w ON w.wr_reason_sk = COALESCE(s.sr_reason_sk, c.cr_reason_sk)
    WHERE s.sr_fee > 20
      AND c.cr_return_amount < 5000
      AND c.sm_contract = '2mM8l'
      AND w.wr_return_amt_inc_tax BETWEEN 100 AND 1000
  )
SELECT
  reason_desc,
  ship_contract,
  SUM(COALESCE(store_net_loss, 0)) AS total_store_net_loss,
  SUM(COALESCE(catalog_net_loss, 0)) AS total_catalog_net_loss,
  COUNT(DISTINCT sr_customer_sk) AS distinct_store_customers,
  COUNT(DISTINCT wr_refunded_customer_sk) AS distinct_web_customers,
  CASE
    WHEN SUM(COALESCE(store_net_loss, 0) + COALESCE(catalog_net_loss, 0)) > 1000 THEN 'High'
    ELSE 'Low'
  END AS loss_category,
  ROW_NUMBER() OVER (PARTITION BY reason_desc ORDER BY SUM(COALESCE(store_net_loss, 0) + COALESCE(catalog_net_loss, 0)) DESC) AS loss_rank
FROM combined
GROUP BY reason_desc, ship_contract
ORDER BY total_store_net_loss DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY

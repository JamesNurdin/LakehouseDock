WITH
  refunded AS (
    SELECT DISTINCT cr_refunded_addr_sk AS address_sk
    FROM catalog_returns
    WHERE cr_fee > 20
  ),
  returning AS (
    SELECT DISTINCT cr_returning_addr_sk AS address_sk
    FROM catalog_returns
    WHERE cr_return_quantity > 5
  ),
  diff_addr AS (
    SELECT address_sk FROM refunded
    EXCEPT
    SELECT address_sk FROM returning
  ),
  common_addr AS (
    SELECT address_sk FROM refunded
    INTERSECT
    SELECT address_sk FROM returning
  ),
  joined AS (
    SELECT
      cr.cr_warehouse_sk,
      cr.cr_call_center_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_fee,
      cc.cc_name,
      cc.cc_company_name,
      w.w_city,
      w.w_zip,
      ca_refunded.ca_state AS refunded_state,
      ca_returning.ca_state AS returning_state,
      hd_refunded.hd_income_band_sk AS refunded_income_band,
      hd_returning.hd_income_band_sk AS returning_income_band,
      ib_refunded.ib_lower_bound AS refunded_income_lower,
      ib_returning.ib_lower_bound AS returning_income_lower
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN call_center cc2 ON cr.cr_call_center_sk = cc2.cc_call_center_sk  -- second alias for extra join
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN income_band ib_refunded ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
    JOIN income_band ib_returning ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
    WHERE EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_warehouse_sk = cr.cr_warehouse_sk
              AND cr2.cr_return_quantity > 8
          )
      AND cr.cr_refunded_addr_sk IN (SELECT address_sk FROM diff_addr)
      AND EXISTS (SELECT 1 FROM common_addr ca WHERE ca.address_sk = cr.cr_returning_addr_sk)
  ),
  agg AS (
    SELECT
      w_city,
      w_zip,
      cc_name,
      cc_company_name,
      SUM(total_return_amount) AS total_return_amount,
      SUM(total_fee) AS total_fee,
      COUNT(*) AS return_cnt
    FROM (
      SELECT
        w_city,
        w_zip,
        cc_name,
        cc_company_name,
        cr_return_amount AS total_return_amount,
        cr_fee AS total_fee
      FROM joined
    ) sub
    GROUP BY w_city, w_zip, cc_name, cc_company_name
  )
SELECT
  w_city,
  cc_name,
  total_return_amount,
  total_fee,
  return_cnt,
  LAG(total_return_amount) OVER (PARTITION BY cc_company_name ORDER BY w_zip) AS lag_total_return_amount
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100

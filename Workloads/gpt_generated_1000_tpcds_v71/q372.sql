WITH avg_fee AS (
    SELECT AVG(cr_fee) AS fee_avg
    FROM catalog_returns
)
SELECT call_center_name,
       customer_id,
       fee,
       return_amount
FROM (
    SELECT
        cc.cc_name AS call_center_name,
        c.c_customer_id AS customer_id,
        cr.cr_fee AS fee,
        cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 120000
      AND cr.cr_fee > (SELECT fee_avg FROM avg_fee)
      AND EXISTS (
          SELECT 1
          FROM customer_address ca
          WHERE ca.ca_address_sk = c.c_current_addr_sk
            AND ca.ca_country = 'JORDAN'
      )
    UNION ALL
    SELECT
        cc.cc_name AS call_center_name,
        c.c_customer_id AS customer_id,
        cr.cr_fee AS fee,
        cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound <= 40000
      AND cr.cr_fee > (SELECT fee_avg FROM avg_fee)
      AND EXISTS (
          SELECT 1
          FROM customer_address ca
          WHERE ca.ca_address_sk = c.c_current_addr_sk
            AND ca.ca_country = 'JORDAN'
      )
) AS combined
ORDER BY fee DESC,
         call_center_name
LIMIT 100

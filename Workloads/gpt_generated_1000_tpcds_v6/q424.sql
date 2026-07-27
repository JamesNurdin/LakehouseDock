WITH base AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_company,
        cc.cc_state,
        cc.cc_county,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_amt_inc_tax,
        cr.cr_return_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_net_loss,
        ca_ret.ca_city AS returning_city,
        ca_ret.ca_state AS returning_state,
        ca_ret.ca_country,
        ca_ret.ca_street_type
    FROM catalog_returns cr
    INNER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_company IN (1, 2, 3)
      AND cc.cc_county LIKE '%County'
      AND cr.cr_return_amount > 100
      AND ca_ret.ca_country = 'United States'
      AND ca_ret.ca_street_type = 'Drive'
)
SELECT
    b.cc_name,
    b.cc_company,
    b.cc_state,
    b.returning_city,
    b.returning_state,
    b.cr_return_quantity,
    b.cr_return_amount,
    b.cr_return_amt_inc_tax,
    CASE
        WHEN b.cr_return_amount > avg_tbl.avg_return THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS amount_category,
    RANK() OVER (PARTITION BY b.cc_company ORDER BY b.cr_return_amount DESC) AS amount_rank,
    ROW_NUMBER() OVER (PARTITION BY b.cc_call_center_sk ORDER BY b.cr_return_amt_inc_tax DESC) AS rn_within_center
FROM base b
CROSS JOIN (
    SELECT AVG(cr_return_amount) AS avg_return FROM catalog_returns
) avg_tbl
ORDER BY amount_rank, b.cr_return_amount DESC
LIMIT 100

WITH base AS (
    SELECT
        cc.cc_call_center_sk AS call_center_sk,
        cc.cc_division AS division,
        t.t_sub_shift AS t_sub_shift,
        ca_refund.ca_state AS refund_state,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_reversed_charge) AS total_reversed_charge,
        CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS return_level
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return
        ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    WHERE cc.cc_class = 'large'
      AND t.t_shift = 'second'
      AND cr.cr_reversed_charge > 500
      AND ca_refund.ca_state = 'CA'
      AND cc.cc_call_center_sk NOT IN (
          SELECT DISTINCT cr2.cr_call_center_sk
          FROM catalog_returns cr2
          WHERE cr2.cr_return_quantity = 0
      )
    GROUP BY
        cc.cc_call_center_sk,
        CUBE (cc.cc_division, t.t_sub_shift, ca_refund.ca_state)
)
SELECT
    division,
    t_sub_shift,
    refund_state,
    return_cnt,
    total_return_amount,
    avg_return_amount,
    total_reversed_charge,
    return_level,
    (
        SELECT SUM(cr3.cr_return_amount)
        FROM catalog_returns cr3
        WHERE cr3.cr_call_center_sk = base.call_center_sk
    ) AS center_total_return,
    ROW_NUMBER() OVER (PARTITION BY division ORDER BY total_return_amount DESC) AS rn
FROM base
ORDER BY total_return_amount DESC
OFFSET 0
LIMIT 100

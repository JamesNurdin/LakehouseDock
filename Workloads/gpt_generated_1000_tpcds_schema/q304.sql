WITH target_cc AS (
    SELECT cc.cc_call_center_sk
    FROM call_center cc
    WHERE cc.cc_state = 'CA'
      AND cc.cc_market_manager = 'Matthew Clifton'
    EXCEPT
    SELECT cs.cs_call_center_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_tax < 40
),
max_tax_sub AS (
    SELECT MAX(cs_ext_tax) AS max_tax
    FROM catalog_sales
    WHERE cs_coupon_amt > 1500
)
SELECT
    cc.cc_market_manager,
    cc.cc_state,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_tax) AS avg_ext_tax,
    MIN(cs.cs_ext_sales_price) AS min_sales_price,
    MAX(cs.cs_coupon_amt) AS max_coupon_amt
FROM catalog_sales cs
FULL OUTER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE (
        (cc.cc_call_center_sk IS NOT NULL AND cc.cc_call_center_sk IN (SELECT cc_call_center_sk FROM target_cc))
        OR (cs.cs_call_center_sk IS NOT NULL AND cs.cs_call_center_sk IN (SELECT cc_call_center_sk FROM target_cc))
    )
    AND cs.cs_ext_tax > 30
    AND cs.cs_coupon_amt BETWEEN 500 AND 2000
    AND cs.cs_ext_sales_price > 100
    AND cs.cs_ext_tax > (SELECT max_tax FROM max_tax_sub)
GROUP BY
    cc.cc_market_manager,
    cc.cc_state
ORDER BY
    total_net_paid DESC
LIMIT 100

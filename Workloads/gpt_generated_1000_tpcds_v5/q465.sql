WITH sales_ship AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        sm.sm_contract,
        sm.sm_type,
        sm.sm_code,
        sm.sm_carrier
    FROM catalog_sales cs
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_ext_sales_price BETWEEN 500 AND 10000
      AND sm.sm_type LIKE 'REG%'
      AND regexp_like(sm.sm_contract, '^[A-Z]{2}[0-9]{2}[A-Z]$')
),
contract_extracted AS (
    SELECT
        sm_contract,
        regexp_extract(sm_contract, '([A-Z]{2})([0-9]{2})([A-Z])', 1) AS prefix,
        regexp_extract(sm_contract, '([A-Z]{2})([0-9]{2})([A-Z])', 2) AS digits,
        regexp_extract(sm_contract, '([A-Z]{2})([0-9]{2})([A-Z])', 3) AS suffix,
        sm_type,
        sm_code,
        sm_carrier,
        cs_ext_sales_price,
        cs_net_profit,
        cs_ext_discount_amt,
        cs_order_number
    FROM sales_ship
)
SELECT
    prefix,
    digits,
    suffix,
    sm_type,
    sm_code,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_net_profit) AS total_net_profit,
    AVG(cs_ext_discount_amt) AS avg_discount,
    SUM(cs_ext_sales_price) AS total_sales
FROM contract_extracted
WHERE CONCAT(prefix, digits) LIKE 'AB%'
GROUP BY
    prefix,
    digits,
    suffix,
    sm_type,
    sm_code
ORDER BY total_net_profit DESC
LIMIT 100

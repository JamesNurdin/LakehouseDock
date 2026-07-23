WITH filtered_ship AS (
    SELECT
        sm_ship_mode_sk,
        sm_type,
        sm_carrier,
        sm_contract,
        SUBSTRING(sm_carrier, 1, 1) AS carrier_initial,
        CASE WHEN REGEXP_LIKE(sm_contract, '\\d') THEN 1 ELSE 0 END AS contract_has_digit,
        REGEXP_EXTRACT(sm_contract, '(\\d+)') AS contract_first_digits
    FROM ship_mode
    WHERE sm_type LIKE '%EXPRESS%'
      AND REGEXP_LIKE(sm_contract, '[A-Za-z0-9]+')
),
filtered_house AS (
    SELECT
        hd_demo_sk,
        hd_buy_potential,
        CASE
            WHEN hd_buy_potential LIKE '%>%' THEN 'high'
            WHEN hd_buy_potential LIKE '5%' THEN 'medium'
            ELSE 'low'
        END AS income_category
    FROM household_demographics
    WHERE hd_buy_potential IS NOT NULL
)
SELECT
    fsm.sm_type,
    fsh.income_category,
    fsm.carrier_initial,
    CONCAT(fsm.sm_carrier, '-', fsh.income_category) AS carrier_income,
    COUNT(DISTINCT fsm.sm_ship_mode_sk) AS distinct_ship_modes,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(*) AS transaction_count
FROM catalog_sales cs
JOIN filtered_ship fsm
    ON cs.cs_ship_mode_sk = fsm.sm_ship_mode_sk
JOIN filtered_house fsh
    ON cs.cs_bill_hdemo_sk = fsh.hd_demo_sk
WHERE cs.cs_ext_sales_price > 1000
  AND fsm.contract_has_digit = 1
  AND fsm.carrier_initial = 'Z'
GROUP BY
    fsm.sm_type,
    fsh.income_category,
    fsm.carrier_initial,
    CONCAT(fsm.sm_carrier, '-', fsh.income_category)
ORDER BY total_net_profit DESC
LIMIT 100

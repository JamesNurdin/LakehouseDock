WITH joined_data AS (
    SELECT
        cc.cc_class,
        cc.cc_country,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        sm.sm_type,
        sm.sm_contract,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        cs.cs_order_number,
        CONCAT(cc.cc_city, ', ', cc.cc_state) AS city_state,
        REGEXP_EXTRACT(sm.sm_contract, '^([A-Z]+)', 1) AS contract_prefix,
        SUBSTRING(cc.cc_name FROM 1 FOR 5) AS name_prefix
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_country = 'United States'
      AND REGEXP_LIKE(cc.cc_name, 'Center')
      AND sm.sm_contract LIKE 'E%'
),
agg_data AS (
    SELECT
        cc_class,
        sm_type,
        contract_prefix,
        MIN(city_state) AS example_city_state,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_coupon_amt) AS total_coupon_amt,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM joined_data
    GROUP BY GROUPING SETS (
        (cc_class, sm_type, contract_prefix),
        (cc_class, contract_prefix),
        (sm_type, contract_prefix),
        (contract_prefix)
    )
)
SELECT
    cc_class,
    sm_type,
    contract_prefix,
    example_city_state,
    total_net_profit,
    total_coupon_amt,
    order_cnt,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_data
ORDER BY profit_rank
LIMIT 100

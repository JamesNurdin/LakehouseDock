WITH catalog_part AS (
    SELECT 
        cc.cc_market_manager AS market_manager,
        cc.cc_state AS state,
        sm.sm_type AS ship_mode_type,
        hd.hd_buy_potential AS buy_potential,
        cs.cs_net_profit AS net_amount
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
      AND cc.cc_state = 'TN'
      AND hd.hd_buy_potential = 'High'
      AND hd.hd_income_band_sk = 3
      AND sm.sm_type = 'AIR'
),
store_part AS (
    SELECT 
        NULL AS market_manager,
        NULL AS state,
        NULL AS ship_mode_type,
        hd.hd_buy_potential AS buy_potential,
        ss.ss_net_profit AS net_amount
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
      AND hd.hd_buy_potential = 'High'
      AND hd.hd_income_band_sk = 3
),
returns_part AS (
    SELECT 
        NULL AS market_manager,
        NULL AS state,
        NULL AS ship_mode_type,
        hd.hd_buy_potential AS buy_potential,
        -sr.sr_net_loss AS net_amount
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2451000
      AND hd.hd_buy_potential = 'High'
      AND hd.hd_income_band_sk = 3
),
combined AS (
    SELECT * FROM catalog_part
    UNION ALL
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM returns_part
),
aggregated AS (
    SELECT 
        market_manager,
        state,
        ship_mode_type,
        buy_potential,
        SUM(net_amount) AS total_net_profit,
        AVG(net_amount) AS avg_net_amount
    FROM combined
    GROUP BY market_manager, state, ship_mode_type, buy_potential
)
SELECT 
    COALESCE(market_manager, 'ALL_MARKETS') AS market_manager,
    COALESCE(state, 'ALL_STATES') AS state,
    COALESCE(ship_mode_type, 'ALL_SHIP_MODES') AS ship_mode_type,
    buy_potential,
    total_net_profit,
    ROUND(avg_net_amount, 2) AS avg_net_amount,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 10

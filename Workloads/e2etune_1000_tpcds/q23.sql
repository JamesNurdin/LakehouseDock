WITH catalog_agg AS (
    SELECT
        cc.cc_market_manager,
        sm.sm_type,
        hd.hd_income_band_sk,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        COUNT(*) AS catalog_txn_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_state = 'TN'
      AND cc.cc_zip = '38828'
      AND cc.cc_market_manager IN ('Julius Tran', 'Gary Colburn')
      AND sm.sm_type = 'AIR'
    GROUP BY cc.cc_market_manager, sm.sm_type, hd.hd_income_band_sk
),
store_return_agg AS (
    SELECT
        hd.hd_income_band_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_txn_cnt
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_income_band_sk
)
SELECT
    ca.cc_market_manager,
    ca.sm_type,
    ca.hd_income_band_sk,
    ca.total_catalog_profit,
    sr.total_return_loss,
    ca.total_catalog_profit - COALESCE(sr.total_return_loss, 0) AS net_profit_after_returns,
    CASE WHEN ca.total_catalog_profit = 0 THEN NULL
         ELSE ROUND((ca.total_catalog_profit - COALESCE(sr.total_return_loss, 0)) / ca.total_catalog_profit, 4)
    END AS profit_retention_ratio,
    RANK() OVER (ORDER BY ca.total_catalog_profit DESC) AS profit_rank
FROM catalog_agg ca
LEFT JOIN store_return_agg sr ON ca.hd_income_band_sk = sr.hd_income_band_sk
WHERE ca.total_catalog_profit > 5000
ORDER BY net_profit_after_returns DESC
LIMIT 20

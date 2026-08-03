/*
  Goal: Analyze net loss/profit across different return and sales channels, categorising outcomes, ranking by magnitude, and deduplicating the combined view while excluding records that also appear in store returns.
*/
WITH
-- Sample a small random fraction of web_sales
ws_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (5)
),
-- Join web_sales to its related dimensions (no reason available, set to NULL)
ws_join AS (
    SELECT
        CAST(NULL AS VARCHAR) AS r_reason_desc,
        ws.ws_net_profit AS net_loss,
        ws.ws_quantity AS quantity,
        CASE WHEN ws.ws_net_profit < 0 THEN 'Loss' ELSE 'Profit' END AS flag,
        ROW_NUMBER() OVER (PARTITION BY CAST(NULL AS VARCHAR) ORDER BY ws.ws_net_profit DESC) AS rank
    FROM ws_sample ws
    LEFT JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    LEFT JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    LEFT JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
-- Join catalog_returns to all its related dimensions, re‑using the Customer table under two aliases
cr_join AS (
    SELECT
        r.r_reason_desc,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS quantity,
        CASE WHEN cr.cr_net_loss > 1000 THEN 'HighLoss' ELSE 'LowLoss' END AS flag,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY cr.cr_net_loss DESC) AS rank
    FROM catalog_returns cr
    LEFT JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    LEFT JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    LEFT JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    LEFT JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    LEFT JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    LEFT JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    LEFT JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    LEFT JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    LEFT JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
),
-- Full outer join between store and store_returns, then bring in the reason dimension
store_full AS (
    SELECT
        r.r_reason_desc,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS quantity,
        CASE WHEN sr.sr_net_loss IS NULL THEN 'NoReturn' ELSE 'Returned' END AS flag,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY sr.sr_net_loss DESC NULLS LAST) AS rank
    FROM store s
    FULL OUTER JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
),
-- Union the two primary feeds (web_sales and catalog_returns) – UNION removes duplicates
union_all AS (
    SELECT r_reason_desc, net_loss, quantity, flag, rank FROM cr_join
    UNION
    SELECT r_reason_desc, net_loss, quantity, flag, rank FROM ws_join
),
-- Exclude any rows that also appear in the store‑return view
final_set AS (
    SELECT * FROM union_all
    EXCEPT
    SELECT r_reason_desc, net_loss, quantity, flag, rank FROM store_full
)
SELECT
    r_reason_desc,
    SUM(net_loss) AS total_net_loss,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT flag) AS distinct_flags
FROM final_set
GROUP BY r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100

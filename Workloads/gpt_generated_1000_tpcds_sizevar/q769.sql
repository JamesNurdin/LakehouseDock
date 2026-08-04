WITH
web_sales_joined AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_ship_mode_sk,
        d.d_year,
        cp.cp_type,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON d.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE d.d_year = 2001
),
web_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_ship_mode_sk,
        d_year,
        cp_type,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales_joined
    GROUP BY ws_warehouse_sk, ws_ship_mode_sk, d_year, cp_type
),
store_returns_joined AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_year,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
),
store_agg AS (
    SELECT
        d_year,
        SUM(sr_return_amt) AS total_return,
        SUM(sr_net_loss) AS total_loss
    FROM store_returns_joined
    GROUP BY d_year
),
date_keys AS (
    SELECT d_date_sk FROM date_dim WHERE d_year = 2001
),
catalog_keys AS (
    SELECT cp_end_date_sk AS d_date_sk FROM catalog_page WHERE cp_type = 'monthly'
),
intersect_keys AS (
    SELECT d_date_sk FROM date_keys
    INTERSECT
    SELECT d_date_sk FROM catalog_keys
),
except_keys AS (
    SELECT d_date_sk FROM date_keys
    EXCEPT
    SELECT d_date_sk FROM catalog_keys
),
filtered_years AS (
    SELECT d.d_year
    FROM intersect_keys ik
    JOIN date_dim d ON ik.d_date_sk = d.d_date_sk
),
full_combined AS (
    SELECT
        wa.ws_warehouse_sk,
        wa.ws_ship_mode_sk,
        wa.d_year,
        wa.cp_type,
        wa.total_sales,
        wa.total_profit,
        NULL AS total_return,
        NULL AS total_loss
    FROM web_agg wa
    FULL OUTER JOIN store_agg sa ON wa.d_year = sa.d_year
),
union_branch AS (
    SELECT * FROM full_combined
    UNION
    SELECT
        NULL AS ws_warehouse_sk,
        NULL AS ws_ship_mode_sk,
        sa.d_year,
        NULL AS cp_type,
        NULL AS total_sales,
        NULL AS total_profit,
        sa.total_return,
        sa.total_loss
    FROM store_agg sa
)
SELECT
    COALESCE(w.w_warehouse_name, 'All Warehouses') AS warehouse_name,
    COALESCE(sm.sm_carrier, 'All Carriers') AS carrier,
    ub.d_year,
    ub.cp_type,
    SUM(ub.total_sales) AS sum_sales,
    SUM(ub.total_profit) AS sum_profit,
    SUM(ub.total_return) AS sum_return,
    SUM(ub.total_loss) AS sum_loss,
    CASE
        WHEN SUM(ub.total_profit) > 0 THEN 'Profit'
        WHEN SUM(ub.total_loss) > 0 THEN 'Loss'
        ELSE 'Neutral'
    END AS overall_status
FROM union_branch ub
LEFT JOIN warehouse w ON ub.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ship_mode sm ON ub.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ub.d_year IN (SELECT d_year FROM filtered_years)
GROUP BY ROLLUP (w.w_warehouse_name, sm.sm_carrier, ub.d_year, ub.cp_type)
ORDER BY w.w_warehouse_name ASC NULLS LAST, ub.d_year DESC
LIMIT 100

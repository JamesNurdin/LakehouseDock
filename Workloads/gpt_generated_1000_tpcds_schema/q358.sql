WITH sr_data AS (
    SELECT
        sr.sr_return_amt_inc_tax,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        sr.sr_net_loss,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 0
      AND hd.hd_dep_count <= 5
      AND ib.ib_lower_bound >= 40000
      AND sr.sr_return_amt_inc_tax > 100
      AND sr.sr_reversed_charge < 500
      AND sr.sr_store_credit <> 0
),
ws_data AS (
    SELECT
        ws.ws_ext_wholesale_cost,
        ws.ws_net_paid_inc_tax,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        hd2.hd_demo_sk,
        hd2.hd_vehicle_count,
        hd2.hd_dep_count,
        ib2.ib_income_band_sk,
        ib2.ib_lower_bound,
        sm.sm_contract,
        sm.sm_type,
        ws_site.web_site_id,
        ws_site.web_country
    FROM web_sales ws
    JOIN household_demographics hd2
        ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2
        ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_ext_wholesale_cost BETWEEN 500 AND 5000
      AND ws.ws_ship_date_sk BETWEEN 2451400 AND 2452800
      AND ws.ws_quantity >= 1
      AND sm.sm_contract IN ('I3uCelXtjP', 'O9V6oF8RJnLMmZYd1')
      AND ws_site.web_country = 'United States'
      AND hd2.hd_vehicle_count IS NOT NULL
),
combined AS (
    SELECT
        COALESCE(sr.hd_demo_sk, ws.hd_demo_sk) AS hd_demo_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        sr.sr_net_loss,
        ws.ws_ext_wholesale_cost,
        ws.ws_net_paid_inc_tax,
        ws.sm_contract,
        ws.web_site_id,
        sr.hd_vehicle_count AS sr_vehicle_count,
        ws.hd_vehicle_count AS ws_vehicle_count,
        sr.hd_dep_count AS sr_dep_count,
        ws.hd_dep_count AS ws_dep_count
    FROM sr_data sr
    FULL OUTER JOIN ws_data ws
        ON sr.hd_demo_sk = ws.hd_demo_sk
),
agg AS (
    SELECT
        hd_demo_sk,
        SUM(COALESCE(sr_return_amt_inc_tax, 0)) AS total_return_amt_inc_tax,
        SUM(COALESCE(ws_ext_wholesale_cost, 0)) AS total_wholesale_cost,
        AVG(COALESCE(sr_net_loss, 0)) AS avg_net_loss,
        COUNT(*) AS row_cnt
    FROM combined
    WHERE (sr_vehicle_count IS NOT NULL OR ws_vehicle_count IS NOT NULL)
      AND (sr_dep_count IS NOT NULL OR ws_dep_count IS NOT NULL)
      AND (sm_contract <> 'ldhM8IvpzHgdbBgDfI' OR sm_contract IS NULL)
      AND (web_site_id <> 'AAAAAAABAAAAAAA' OR web_site_id IS NULL)
    GROUP BY hd_demo_sk
    HAVING SUM(COALESCE(sr_return_amt_inc_tax, 0)) > (
        SELECT AVG(sr_return_amt_inc_tax) FROM store_returns
    )
)
SELECT
    hd_demo_sk,
    total_return_amt_inc_tax,
    total_wholesale_cost,
    avg_net_loss,
    row_cnt,
    ROW_NUMBER() OVER (ORDER BY total_return_amt_inc_tax DESC) AS rn
FROM agg
ORDER BY total_return_amt_inc_tax DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

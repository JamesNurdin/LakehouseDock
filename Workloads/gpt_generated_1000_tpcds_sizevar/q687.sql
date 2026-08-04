WITH
store_return_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        d.d_year,
        t.t_hour,
        hd.hd_income_band_sk,
        r.r_reason_desc,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND t.t_hour BETWEEN 8 AND 20
      AND hd.hd_vehicle_count >= 1
    GROUP BY sr.sr_store_sk, sr.sr_reason_sk, d.d_year, t.t_hour, hd.hd_income_band_sk, r.r_reason_desc
),

sales_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_hdemo_sk,
        d.d_year,
        t.t_hour,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_paid_inc_ship) AS total_sales,
        AVG(ws.ws_net_paid_inc_ship) AS avg_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND hd.hd_income_band_sk = 5
    GROUP BY ws.ws_sold_date_sk, ws.ws_sold_time_sk, ws.ws_bill_hdemo_sk, d.d_year, t.t_hour, hd.hd_income_band_sk
),

common_dims AS (
    SELECT d_year, t_hour, hd_income_band_sk FROM (
        SELECT d.d_year, t.t_hour, hd.hd_income_band_sk
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    )
    INTERSECT
    SELECT d_year, t_hour, hd_income_band_sk FROM (
        SELECT d.d_year, t.t_hour, hd.hd_income_band_sk
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    )
),

store_catalog AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_market_manager,
        cp.cp_catalog_page_id,
        cp.cp_type,
        d.d_date
    FROM store s
    FULL OUTER JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    FULL OUTER JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE s.s_market_manager IN ('Lawrence Nettles', 'Dean Morrison')
      AND cp.cp_type = 'Holiday'
),

store_hours AS (
    SELECT
        s.s_store_sk,
        hour_part
    FROM store s
    CROSS JOIN UNNEST(split(s.s_hours, ',')) AS t(hour_part)
    WHERE s.s_hours IS NOT NULL
)
SELECT
    sc.s_store_sk,
    sc.s_store_name,
    sc.s_market_manager,
    sc.cp_catalog_page_id,
    cd.d_year,
    cd.t_hour,
    cd.hd_income_band_sk,
    ra.total_return_amt,
    ra.cnt_returns,
    ra.r_reason_desc,
    sa.total_sales,
    sa.avg_sales,
    (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_store_sk = sc.s_store_sk) AS total_return_events,
    COUNT(sh.hour_part) AS hours_recorded
FROM store_catalog sc
JOIN common_dims cd ON 1 = 1
LEFT JOIN store_return_agg ra
    ON ra.sr_store_sk = sc.s_store_sk
   AND ra.d_year = cd.d_year
   AND ra.t_hour = cd.t_hour
   AND ra.hd_income_band_sk = cd.hd_income_band_sk
LEFT JOIN sales_agg sa
    ON sa.d_year = cd.d_year
   AND sa.t_hour = cd.t_hour
   AND sa.hd_income_band_sk = cd.hd_income_band_sk
LEFT JOIN store_hours sh ON sh.s_store_sk = sc.s_store_sk
GROUP BY
    sc.s_store_sk,
    sc.s_store_name,
    sc.s_market_manager,
    sc.cp_catalog_page_id,
    cd.d_year,
    cd.t_hour,
    cd.hd_income_band_sk,
    ra.total_return_amt,
    ra.cnt_returns,
    ra.r_reason_desc,
    sa.total_sales,
    sa.avg_sales
ORDER BY sc.s_store_sk, cd.d_year DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY

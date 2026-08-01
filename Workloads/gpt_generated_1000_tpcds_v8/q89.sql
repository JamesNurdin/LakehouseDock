WITH ws_agg AS (
        SELECT
            ws_sold_date_sk,
            ws_sold_time_sk,
            ws_bill_hdemo_sk,
            ws_ship_hdemo_sk,
            ws_ship_mode_sk,
            SUM(ws_net_paid) AS total_net_paid,
            SUM(ws_ext_tax) AS total_tax,
            COUNT(*) AS sales_cnt
        FROM web_sales
        WHERE ws_ext_wholesale_cost > 500
          AND ws_net_profit > 0
        GROUP BY ws_sold_date_sk, ws_sold_time_sk, ws_bill_hdemo_sk, ws_ship_hdemo_sk, ws_ship_mode_sk
    ),
    sr_agg AS (
        SELECT
            sr_returned_date_sk,
            sr_return_time_sk,
            sr_hdemo_sk,
            sr_store_sk,
            SUM(sr_net_loss) AS total_net_loss,
            COUNT(*) AS returns_cnt
        FROM store_returns
        WHERE sr_return_ship_cost > 100
        GROUP BY sr_returned_date_sk, sr_return_time_sk, sr_hdemo_sk, sr_store_sk
    ),
    unioned AS (
        SELECT
            'web' AS src,
            ws_sold_date_sk      AS date_sk,
            ws_sold_time_sk      AS time_sk,
            ws_bill_hdemo_sk     AS hdemo_sk,
            NULL                 AS store_sk,
            ws_ship_mode_sk      AS ship_mode_sk,
            total_net_paid       AS amount,
            sales_cnt            AS cnt
        FROM ws_agg
        UNION ALL
        SELECT
            'store_return' AS src,
            sr_returned_date_sk AS date_sk,
            sr_return_time_sk   AS time_sk,
            sr_hdemo_sk        AS hdemo_sk,
            sr_store_sk        AS store_sk,
            NULL               AS ship_mode_sk,
            -total_net_loss    AS amount,
            returns_cnt        AS cnt
        FROM sr_agg
    )
SELECT
    u.src,
    d.d_year,
    t.t_hour,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    sm.sm_type,
    COALESCE(s.s_state, 'UNKNOWN') AS state,
    u.amount,
    u.cnt,
    ROW_NUMBER() OVER (PARTITION BY u.src ORDER BY u.amount DESC) AS rn,
    RANK()        OVER (PARTITION BY u.src ORDER BY u.amount DESC) AS rk,
    CASE WHEN u.amount > (SELECT AVG(amount) FROM unioned) THEN 'Above Avg' ELSE 'Below Avg' END AS amount_category
FROM unioned u
JOIN date_dim d     ON u.date_sk = d.d_date_sk
JOIN time_dim t     ON u.time_sk = t.t_time_sk
JOIN household_demographics hd ON u.hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN ship_mode sm   ON u.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN store s        ON u.store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 2001 AND 2002
  AND t.t_hour BETWEEN 9 AND 17
  AND hd.hd_dep_count >= 4
  AND ib.ib_upper_bound <= 50000
  AND sm.sm_type = 'AIR'
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_return_quantity > 5
          AND sr2.sr_returned_date_sk = u.date_sk
    )
  AND s.s_tax_percentage > (SELECT MAX(s_tax_percentage) FROM store)
ORDER BY u.amount DESC, rn
LIMIT 100

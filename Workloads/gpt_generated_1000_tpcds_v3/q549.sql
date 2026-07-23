WITH hd_sales AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        SUM(COALESCE(cs.cs_net_paid_inc_ship_tax, 0)) AS cs_total_net_paid,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS ss_total_net_paid,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS ws_total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS cs_order_cnt,
        COUNT(DISTINCT ss.ss_ticket_number) AS ss_ticket_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS ws_order_cnt
    FROM household_demographics hd
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_demo_sk, ib.ib_income_band_sk
)
SELECT
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cc.cc_call_center_id,
    s.s_store_name,
    sm.sm_ship_mode_id,
    w.w_warehouse_name,
    ws.ws_order_number,
    (hd_sales.cs_total_net_paid + hd_sales.ss_total_net_paid + hd_sales.ws_total_net_paid) AS total_net_paid,
    ROW_NUMBER() OVER (
        PARTITION BY ib.ib_income_band_sk
        ORDER BY (hd_sales.cs_total_net_paid + hd_sales.ss_total_net_paid + hd_sales.ws_total_net_paid) DESC
    ) AS rank_in_income_band
FROM household_demographics hd
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN catalog_sales cs
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN hd_sales
    ON hd_sales.hd_demo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count > 1
  AND cc.cc_state = 'CA'
  AND cs.cs_net_paid_inc_ship_tax > 1000
  AND sm.sm_type = 'AIR'
  AND EXISTS (
        SELECT 1
        FROM (
            SELECT cs_inner.cs_call_center_sk AS ref_id
            FROM catalog_sales cs_inner
            WHERE cs_inner.cs_net_profit > 500
            UNION
            SELECT ws_inner.ws_warehouse_sk AS ref_id
            FROM web_sales ws_inner
            WHERE ws_inner.ws_net_profit > 500
        ) u
        WHERE u.ref_id = cc.cc_call_center_sk
    )
  AND ws.ws_order_number IN (
        SELECT DISTINCT order_num
        FROM (
            SELECT cs.cs_order_number AS order_num FROM catalog_sales cs
            UNION
            SELECT ws.ws_order_number AS order_num FROM web_sales ws
        ) sub
    )
ORDER BY total_net_paid DESC
LIMIT 100

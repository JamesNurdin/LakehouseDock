WITH joined AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        sm.sm_ship_mode_id,
        sm.sm_type,
        d_cs.d_year,
        hd_bill.hd_income_band_sk,
        cs.cs_net_profit AS cs_net_profit,
        ss.ss_net_profit AS ss_net_profit,
        (cs.cs_net_profit + ss.ss_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    -- store_sales branch
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_cs.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_cs.d_year = 2001
      AND hd_bill.hd_income_band_sk IN (2, 4, 6)
      AND sm.sm_type = 'AIR'
      AND s.s_state = 'CA'
      AND hd_ss.hd_vehicle_count > 0
),
agg AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_state,
        sm_ship_mode_id,
        d_year,
        SUM(total_profit) AS store_ship_profit,
        COUNT(*) AS txn_cnt
    FROM joined
    GROUP BY s_store_sk, s_store_name, s_state, sm_ship_mode_id, d_year
),
final AS (
    SELECT
        a.s_store_sk,
        a.s_store_name,
        a.s_state,
        a.sm_ship_mode_id,
        a.store_ship_profit,
        a.txn_cnt,
        (SELECT AVG(b.store_ship_profit)
         FROM agg b
         WHERE b.s_store_sk = a.s_store_sk) AS avg_store_profit,
        RANK() OVER (PARTITION BY a.s_state ORDER BY a.store_ship_profit DESC) AS profit_rank_state,
        SUM(a.store_ship_profit) OVER (PARTITION BY a.s_state) AS total_profit_state
    FROM agg a
)
SELECT *
FROM final
ORDER BY store_ship_profit DESC
LIMIT 100

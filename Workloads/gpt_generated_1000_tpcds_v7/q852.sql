WITH sales_agg AS (
    SELECT
        cc.cc_name,
        sm.sm_ship_mode_id,
        d.d_year,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_day,
        COUNT(DISTINCT st.s_store_id) AS store_cnt,
        AVG(hd.hd_income_band_sk) AS avg_income_band,
        SUM(CASE WHEN t.t_hour BETWEEN 9 AND 17 THEN cs.cs_net_paid_inc_tax ELSE 0 END) AS sales_daytime
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN store st
        ON st.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
      AND sm.sm_carrier = 'AIRBORNE'
      AND st.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cc.cc_name, sm.sm_ship_mode_id, d.d_year
),
returns_agg AS (
    SELECT
        cc.cc_name,
        sm.sm_ship_mode_id,
        d.d_year,
        SUM(cr.cr_net_loss) AS total_returns
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
      AND sm.sm_carrier = 'AIRBORNE'
    GROUP BY cc.cc_name, sm.sm_ship_mode_id, d.d_year
)
SELECT
    s.cc_name,
    s.sm_ship_mode_id,
    s.d_year,
    s.total_sales,
    r.total_returns,
    (s.total_sales - COALESCE(r.total_returns, 0)) AS net_amount,
    s.total_profit,
    s.total_inventory_on_day,
    s.store_cnt,
    s.avg_income_band,
    s.sales_daytime,
    RANK() OVER (PARTITION BY s.d_year ORDER BY (s.total_sales - COALESCE(r.total_returns, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cc_name = r.cc_name
   AND s.sm_ship_mode_id = r.sm_ship_mode_id
   AND s.d_year = r.d_year
WHERE s.total_sales > 100000
ORDER BY s.d_year, profit_rank
LIMIT 100

WITH base AS (
    SELECT
        s.s_state,
        cd.cd_gender,
        c.c_customer_id,
        cs.cs_net_profit AS cs_profit,
        ws.ws_net_profit AS ws_profit,
        COALESCE(sr.sr_net_loss, 0) AS sr_loss,
        COALESCE(wr.wr_net_loss, 0) AS wr_loss,
        cs.cs_ext_ship_cost,
        cp.cp_catalog_number,
        sm.sm_type,
        ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
     AND wr.wr_order_number = ws.ws_order_number
    WHERE cs.cs_ext_ship_cost > 100
      AND cp.cp_catalog_number BETWEEN 10 AND 20
      AND cd.cd_gender = 'M'
      AND ib.ib_upper_bound >= 80000
      AND sm.sm_type = 'AIR'
),
agg AS (
    SELECT
        s_state,
        cd_gender,
        SUM(cs_profit + ws_profit - sr_loss - wr_loss) AS total_profit,
        CASE WHEN SUM(cs_profit + ws_profit) > 50000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag
    FROM base
    GROUP BY ROLLUP (s_state, cd_gender)
    HAVING SUM(cs_profit + ws_profit - sr_loss - wr_loss) IS NOT NULL
)
SELECT
    s_state,
    cd_gender,
    total_profit,
    profit_flag,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_profit DESC) AS state_rank
FROM agg
ORDER BY s_state, cd_gender

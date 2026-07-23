/*
Goal: Rank stores by net profit for the year 2001 while comparing their performance to web site sales, inventory levels, call‑center activity and catalog page events. The query also classifies each store’s profit relative to the average store profit and flags web profit positivity.
*/
WITH
store_agg AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        d_sales.d_year,
        SUM(ss.ss_net_profit) AS total_store_net_profit,
        COUNT(*) AS total_store_transactions
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales
        ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN household_demographics hd_sales
        ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    WHERE d_sales.d_year = 2001
      AND s.s_state = 'CA'
      AND hd_sales.hd_income_band_sk IN (1, 2, 3)
    GROUP BY ss.ss_store_sk, s.s_store_name, s.s_state, d_sales.d_year
),
web_agg AS (
    SELECT
        ws.ws_web_site_sk,
        we.web_name,
        d_ws.d_year,
        SUM(ws.ws_net_profit) AS total_web_net_profit,
        COUNT(*) AS total_web_transactions
    FROM web_sales ws
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d_ws.d_year = 2001
      AND sm.sm_type = 'EXPRESS'
      AND we.web_country = 'United States'
      AND r.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY ws.ws_web_site_sk, we.web_name, d_ws.d_year
),
inventory_agg AS (
    SELECT
        d_inv.d_year,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    GROUP BY d_inv.d_year
),
call_center_agg AS (
    SELECT
        d_cc.d_year,
        COUNT(*) AS call_center_events,
        MAX(cc.cc_manager) AS cc_manager
    FROM call_center cc
    JOIN date_dim d_cc
        ON cc.cc_closed_date_sk = d_cc.d_date_sk
    WHERE d_cc.d_year = 2001
    GROUP BY d_cc.d_year
),
catalog_page_agg AS (
    SELECT
        d_cp.d_year,
        COUNT(*) AS catalog_page_events,
        MAX(cp.cp_description) AS cp_description
    FROM catalog_page cp
    JOIN date_dim d_cp
        ON cp.cp_start_date_sk = d_cp.d_date_sk
    WHERE d_cp.d_year = 2001
    GROUP BY d_cp.d_year
)
SELECT
    sa.d_year,
    sa.s_store_name,
    sa.s_state,
    sa.total_store_net_profit,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.total_store_net_profit DESC) AS store_profit_rank,
    wa.web_name,
    wa.total_web_net_profit,
    ia.total_quantity_on_hand,
    cca.cc_manager,
    cpa.cp_description,
    CASE
        WHEN sa.total_store_net_profit > (SELECT AVG(total_store_net_profit) FROM store_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg,
    CASE
        WHEN wa.total_web_net_profit > 0 THEN 'Web Profit Positive'
        ELSE 'Web Profit Zero'
    END AS web_profit_flag
FROM store_agg sa
JOIN web_agg wa
    ON sa.d_year = wa.d_year
LEFT JOIN inventory_agg ia
    ON ia.d_year = sa.d_year
LEFT JOIN call_center_agg cca
    ON cca.d_year = sa.d_year
LEFT JOIN catalog_page_agg cpa
    ON cpa.d_year = sa.d_year
WHERE sa.total_store_transactions > 10
  AND wa.total_web_transactions > 10
  AND ia.total_quantity_on_hand > 0
ORDER BY store_profit_rank ASC, sa.total_store_net_profit DESC
LIMIT 100

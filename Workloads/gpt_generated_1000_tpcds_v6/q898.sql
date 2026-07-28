WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit AS catalog_net_profit,
        ws.ws_net_profit AS web_net_profit,
        ws.ws_order_number,
        d.d_year,
        d.d_moy,
        w.w_warehouse_name,
        w.w_state,
        cc.cc_market_manager,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        st.s_store_name,
        inv.inv_quantity_on_hand,
        td.t_hour,
        wp.wp_type
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
       AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN store st
        ON st.s_closed_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 1913
      AND d.d_moy = 5
      AND w.w_state = 'CA'
      AND ib.ib_lower_bound >= 30000
      AND cc.cc_market_manager = 'Frederick Weaver'
),
order_with_return AS (
    SELECT
        sb.w_warehouse_name,
        (sb.catalog_net_profit + sb.web_net_profit) AS total_net_profit,
        CASE WHEN EXISTS (
                SELECT 1
                FROM web_returns wr
                WHERE wr.wr_order_number = sb.ws_order_number
                  AND wr.wr_return_amt > 0
            ) THEN 1 ELSE 0 END AS has_return
    FROM sales_base sb
)
SELECT
    owr.w_warehouse_name,
    AVG(owr.total_net_profit) AS avg_total_profit,
    SUM(owr.has_return) AS orders_with_return
FROM order_with_return owr
GROUP BY owr.w_warehouse_name
ORDER BY avg_total_profit DESC
LIMIT 100

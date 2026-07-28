WITH sales_agg AS (
    SELECT
        i.i_category,
        sm.sm_type,
        td_cs.t_hour,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(wr.wr_net_loss) AS returns_loss,
        SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss) AS net_total,
        CASE WHEN (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss)) > 10000
             THEN 'High' ELSE 'Low' END AS profit_flag
    FROM catalog_sales cs
    JOIN time_dim td_cs
        ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_sales ws
        ON cs.cs_order_number = ws.ws_order_number
    JOIN time_dim td_ws
        ON ws.ws_sold_time_sk = td_ws.t_time_sk
    JOIN household_demographics hd_ws_bill
        ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN household_demographics hd_ws_ship
        ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    JOIN time_dim td_wr
        ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_wr_refunded
        ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    JOIN household_demographics hd_wr_returning
        ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td_cs.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 50000
      AND i.i_category = 'Electronics'
      AND sm.sm_type = 'AIR'
    GROUP BY GROUPING SETS (
        (i.i_category, sm.sm_type, td_cs.t_hour),
        (i.i_category, sm.sm_type),
        (i.i_category),
        ()
    )
)
SELECT
    i_category,
    sm_type,
    t_hour,
    catalog_profit,
    web_profit,
    returns_loss,
    net_total,
    profit_flag,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY net_total DESC) AS rank_within_category
FROM sales_agg
ORDER BY net_total DESC
LIMIT 100

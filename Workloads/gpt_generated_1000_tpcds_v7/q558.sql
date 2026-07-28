WITH per_group AS (
    SELECT
        cc.cc_call_center_id,
        d.d_year,
        t.t_hour,
        i.i_category,
        ib.ib_lower_bound,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(sr.sr_net_loss) AS returns_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt
    FROM call_center cc
    LEFT JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN time_dim t2
        ON ws.ws_sold_time_sk = t2.t_time_sk
    WHERE d.d_year = 2001
      AND t.t_hour IN (8, 12, 18)
      AND ib.ib_lower_bound >= 50000
      AND r.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY
        cc.cc_call_center_id,
        d.d_year,
        t.t_hour,
        i.i_category,
        ib.ib_lower_bound
)
SELECT
    cc_call_center_id,
    AVG(total_profit) AS avg_total_profit,
    COUNT(*) AS periods
FROM (
    SELECT
        cc_call_center_id,
        (store_sales_profit + web_sales_profit - returns_loss) AS total_profit
    FROM per_group
) agg
GROUP BY cc_call_center_id
HAVING AVG(total_profit) > 10000
ORDER BY avg_total_profit DESC
LIMIT 5

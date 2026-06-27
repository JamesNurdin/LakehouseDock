WITH store_agg AS (
    SELECT
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        t.t_hour AS hour_of_day,
        SUM(ss.ss_net_profit) AS sales_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS returns_loss
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, t.t_hour
),
catalog_agg AS (
    SELECT
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        t.t_hour AS hour_of_day,
        SUM(cs.cs_net_profit) AS sales_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS returns_loss
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, t.t_hour
),
web_agg AS (
    SELECT
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        t.t_hour AS hour_of_day,
        SUM(ws.ws_net_profit) AS sales_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS returns_loss
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, t.t_hour
),
combined AS (
    SELECT income_lower, income_upper, hour_of_day, sales_profit - returns_loss AS net_profit
    FROM store_agg
    UNION ALL
    SELECT income_lower, income_upper, hour_of_day, sales_profit - returns_loss
    FROM catalog_agg
    UNION ALL
    SELECT income_lower, income_upper, hour_of_day, sales_profit - returns_loss
    FROM web_agg
)
SELECT
    income_lower,
    income_upper,
    hour_of_day,
    SUM(net_profit) AS total_net_profit
FROM combined
GROUP BY income_lower, income_upper, hour_of_day
ORDER BY income_lower, hour_of_day

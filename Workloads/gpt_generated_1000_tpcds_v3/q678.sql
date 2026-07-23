WITH agg_by_store AS (
    SELECT
        s.s_store_sk AS store_sk,
        s.s_store_name AS store_name,
        s.s_state AS state,
        SUM(ss.ss_net_profit) AS total_store_sales_profit,
        SUM(ws.ws_net_profit) AS total_web_sales_profit,
        SUM(sr.sr_net_loss) AS total_store_returns_loss,
        SUM(wr.wr_net_loss) AS total_web_returns_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_web_sales,
        CASE
            WHEN SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) > 0
            THEN 'Overall Profit'
            ELSE 'Overall Loss'
        END AS profit_category,
        (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss))) AS net_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE
        s.s_state = 'CA'
        AND s.s_gmt_offset BETWEEN -8 AND -5
        AND cd.cd_gender = 'M'
        AND ib.ib_upper_bound >= 60000
        AND sr.sr_return_ship_cost > 0
        AND ws.ws_quantity > 2
        AND ws.ws_net_paid > 100
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state
)
SELECT
    store_sk,
    store_name,
    state,
    profit_category,
    total_store_sales_profit,
    total_web_sales_profit,
    total_store_returns_loss,
    total_web_returns_loss,
    net_profit,
    CASE
        WHEN total_store_sales_profit > total_web_sales_profit THEN 'StoreHigher'
        WHEN total_store_sales_profit < total_web_sales_profit THEN 'WebHigher'
        ELSE 'Equal'
    END AS sales_comparison,
    (SELECT AVG(total_store_sales_profit) FROM agg_by_store) AS avg_store_sales_profit_all
FROM agg_by_store
WHERE net_profit > (SELECT AVG(net_profit) FROM agg_by_store)
ORDER BY net_profit DESC
LIMIT 100

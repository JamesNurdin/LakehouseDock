WITH
    store_channel AS (
        SELECT
            s.s_store_name AS store_name,
            ib.ib_lower_bound AS income_lower,
            ib.ib_upper_bound AS income_upper,
            SUM(ss.ss_net_profit) AS net_profit,
            SUM(sr.sr_net_loss) AS net_loss
        FROM store_sales ss
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN store_returns sr
            ON sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_store_sk = s.s_store_sk
        GROUP BY s.s_store_name, ib.ib_lower_bound, ib.ib_upper_bound
    ),
    catalog_channel AS (
        SELECT
            NULL AS store_name,
            ib.ib_lower_bound AS income_lower,
            ib.ib_upper_bound AS income_upper,
            SUM(cs.cs_net_profit) AS net_profit,
            SUM(cr.cr_net_loss) AS net_loss
        FROM catalog_sales cs
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_order_number = cs.cs_order_number
        GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
    ),
    web_channel AS (
        SELECT
            NULL AS store_name,
            ib.ib_lower_bound AS income_lower,
            ib.ib_upper_bound AS income_upper,
            SUM(ws.ws_net_profit) AS net_profit,
            SUM(wr.wr_net_loss) AS net_loss
        FROM web_sales ws
        JOIN customer c
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
            ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN web_returns wr
            ON wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_order_number = ws.ws_order_number
        GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
    )
SELECT
    'Store'   AS channel,
    store_name,
    income_lower,
    income_upper,
    net_profit,
    net_loss,
    net_profit - net_loss AS net_profit_after_returns
FROM store_channel
UNION ALL
SELECT
    'Catalog' AS channel,
    store_name,
    income_lower,
    income_upper,
    net_profit,
    net_loss,
    net_profit - net_loss AS net_profit_after_returns
FROM catalog_channel
UNION ALL
SELECT
    'Web'     AS channel,
    store_name,
    income_lower,
    income_upper,
    net_profit,
    net_loss,
    net_profit - net_loss AS net_profit_after_returns
FROM web_channel
ORDER BY channel, store_name, income_lower

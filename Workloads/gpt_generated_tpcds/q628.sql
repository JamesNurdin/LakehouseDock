WITH
store_data AS (
    SELECT
        'store' AS channel,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(sr.sr_return_amt) AS return_amount,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(sr.sr_net_loss) AS net_loss
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
catalog_data AS (
    SELECT
        'catalog' AS channel,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
web_data AS (
    SELECT
        'web' AS channel,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        SUM(wr.wr_return_amt) AS return_amount,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(wr.wr_net_loss) AS net_loss
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
combined AS (
    SELECT
        channel,
        income_lower,
        income_upper,
        sales_amount AS total_sales,
        return_amount AS total_returns,
        net_profit AS total_profit,
        net_loss AS total_loss
    FROM store_data
    UNION ALL
    SELECT
        channel,
        income_lower,
        income_upper,
        sales_amount,
        return_amount,
        net_profit,
        net_loss
    FROM catalog_data
    UNION ALL
    SELECT
        channel,
        income_lower,
        income_upper,
        sales_amount,
        return_amount,
        net_profit,
        net_loss
    FROM web_data
)
SELECT
    channel,
    income_lower,
    income_upper,
    total_sales,
    total_returns,
    total_profit,
    total_loss,
    CASE WHEN total_sales > 0 THEN total_returns / total_sales ELSE 0 END AS return_rate
FROM combined
ORDER BY channel, income_lower

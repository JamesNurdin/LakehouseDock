WITH combined AS (
    -- Store sales (store channel)
    SELECT
        ib.ib_income_band_sk AS income_band_sk,
        ib.ib_lower_bound   AS lower_bound,
        ib.ib_upper_bound   AS upper_bound,
        ss.ss_net_profit    AS net_profit,
        NULL                AS net_loss,
        ss.ss_quantity      AS quantity,
        ss.ss_ext_discount_amt AS discount_amt,
        NULL                AS return_quantity,
        NULL                AS return_amt,
        'store'             AS channel
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Web sales (web channel)
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_net_profit,
        NULL,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        NULL,
        NULL,
        'web'
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Store returns (store channel)
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        NULL,
        sr.sr_net_loss,
        NULL,
        NULL,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        'store'
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Web returns (web channel)
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        NULL,
        wr.wr_net_loss,
        NULL,
        NULL,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        'web'
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    income_band_sk,
    lower_bound,
    upper_bound,
    SUM(CASE WHEN channel = 'store' THEN net_profit ELSE 0 END) AS total_store_net_profit,
    SUM(CASE WHEN channel = 'web'   THEN net_profit ELSE 0 END) AS total_web_net_profit,
    SUM(CASE WHEN channel = 'store' THEN net_loss   ELSE 0 END) AS total_store_net_loss,
    SUM(CASE WHEN channel = 'web'   THEN net_loss   ELSE 0 END) AS total_web_net_loss,
    SUM(quantity)        AS total_quantity_sold,
    SUM(discount_amt)    AS total_discount_amount,
    SUM(return_quantity) AS total_return_quantity,
    SUM(return_amt)      AS total_return_amount
FROM combined
GROUP BY
    income_band_sk,
    lower_bound,
    upper_bound
ORDER BY
    income_band_sk

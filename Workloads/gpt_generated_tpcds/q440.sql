WITH unified AS (
    -- Store sales (profit only)
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_net_profit               AS profit,
        CAST(0 AS decimal(7,2))        AS loss,
        'store'                         AS src
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Web sales (profit only)
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_net_profit               AS profit,
        CAST(0 AS decimal(7,2))        AS loss,
        'web'                           AS src
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Web returns (loss only)
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CAST(0 AS decimal(7,2))        AS profit,
        wr.wr_net_loss                 AS loss,
        'return'                        AS src
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ib_lower_bound,
    ib_upper_bound,
    SUM(CASE WHEN src = 'store' THEN profit ELSE 0 END) AS total_store_net_profit,
    SUM(CASE WHEN src = 'web'   THEN profit ELSE 0 END) AS total_web_net_profit,
    SUM(loss)                                            AS total_return_loss,
    SUM(profit) - SUM(loss)                              AS total_net_profit
FROM unified
GROUP BY
    c_customer_id,
    c_first_name,
    c_last_name,
    ib_lower_bound,
    ib_upper_bound
ORDER BY total_net_profit DESC
LIMIT 10

WITH
    store_sales_agg AS (
        SELECT
            ss.ss_hdemo_sk AS hd_demo_sk,
            SUM(ss.ss_net_paid) AS store_total_net_paid,
            SUM(ss.ss_net_profit) AS store_total_net_profit
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        GROUP BY ss.ss_hdemo_sk
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_bill_hdemo_sk AS hd_demo_sk,
            SUM(ws.ws_net_paid) AS web_total_net_paid,
            SUM(ws.ws_net_profit) AS web_total_net_profit
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        GROUP BY ws.ws_bill_hdemo_sk
    ),
    returns_agg AS (
        SELECT
            sr.sr_hdemo_sk AS hd_demo_sk,
            SUM(sr.sr_net_loss) AS total_net_loss,
            COUNT(*) AS return_count
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        GROUP BY sr.sr_hdemo_sk
    )
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    hd.hd_income_band_sk,
    COALESCE(ss.store_total_net_paid, 0) + COALESCE(ws.web_total_net_paid, 0) AS total_net_paid,
    COALESCE(ss.store_total_net_profit, 0) + COALESCE(ws.web_total_net_profit, 0) AS total_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    CASE
        WHEN (COALESCE(ss.store_total_net_paid, 0) + COALESCE(ws.web_total_net_paid, 0)) = 0 THEN 0
        ELSE COALESCE(r.total_net_loss, 0) / (COALESCE(ss.store_total_net_paid, 0) + COALESCE(ws.web_total_net_paid, 0))
    END AS return_loss_rate
FROM household_demographics hd
LEFT JOIN store_sales_agg ss ON ss.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN web_sales_agg ws ON ws.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN returns_agg r ON r.hd_demo_sk = hd.hd_demo_sk
ORDER BY total_net_profit DESC
LIMIT 10

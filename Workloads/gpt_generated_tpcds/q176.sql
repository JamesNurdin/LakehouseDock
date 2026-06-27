WITH
    ws_agg AS (
        SELECT ws_bill_customer_sk,
               SUM(ws_net_paid_inc_tax) AS total_web_sales,
               SUM(ws_net_profit)       AS total_web_profit
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    ),
    sr_agg AS (
        SELECT sr_customer_sk,
               SUM(sr_net_loss) AS total_store_returns
        FROM store_returns
        GROUP BY sr_customer_sk
    ),
    wr_agg AS (
        SELECT wr_refunded_customer_sk,
               SUM(wr_net_loss) AS total_web_returns
        FROM web_returns
        GROUP BY wr_refunded_customer_sk
    )
SELECT
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    COALESCE(ws_agg.total_web_sales, 0)   AS total_web_sales,
    COALESCE(ws_agg.total_web_profit, 0)  AS total_web_profit,
    COALESCE(sr_agg.total_store_returns, 0) AS total_store_returns,
    COALESCE(wr_agg.total_web_returns, 0)   AS total_web_returns,
    COALESCE(ws_agg.total_web_sales, 0) - COALESCE(sr_agg.total_store_returns, 0) - COALESCE(wr_agg.total_web_returns, 0) AS net_revenue
FROM
    customer AS c
LEFT JOIN
    customer_demographics AS cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN
    household_demographics AS hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN
    ws_agg
        ON c.c_customer_sk = ws_agg.ws_bill_customer_sk
LEFT JOIN
    sr_agg
        ON c.c_customer_sk = sr_agg.sr_customer_sk
LEFT JOIN
    wr_agg
        ON c.c_customer_sk = wr_agg.wr_refunded_customer_sk
WHERE
    c.c_preferred_cust_flag = 'Y'
ORDER BY
    net_revenue DESC
LIMIT 100

WITH catalog_ret AS (
    SELECT cr_refunded_hdemo_sk AS hd_demo_sk,
           SUM(cr_return_amount) AS total_catalog_return,
           SUM(cr_net_loss)      AS total_catalog_loss
    FROM catalog_returns
    GROUP BY cr_refunded_hdemo_sk
),
store_ret AS (
    SELECT sr_hdemo_sk AS hd_demo_sk,
           SUM(sr_return_amt) AS total_store_return,
           SUM(sr_net_loss)   AS total_store_loss
    FROM store_returns
    GROUP BY sr_hdemo_sk
),
web_sales_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           SUM(ws_net_profit)      AS total_profit
    FROM web_sales
    GROUP BY ws_bill_hdemo_sk
)
SELECT hd.hd_demo_sk,
       hd.hd_income_band_sk,
       hd.hd_buy_potential,
       hd.hd_dep_count,
       hd.hd_vehicle_count,
       COALESCE(ws.total_sales, 0)               AS total_sales,
       COALESCE(ws.total_profit, 0)              AS total_profit,
       COALESCE(sr.total_store_return, 0)        AS total_store_return,
       COALESCE(sr.total_store_loss, 0)          AS total_store_loss,
       COALESCE(cr.total_catalog_return, 0)      AS total_catalog_return,
       COALESCE(cr.total_catalog_loss, 0)        AS total_catalog_loss,
       (COALESCE(ws.total_profit, 0)
        - COALESCE(sr.total_store_loss, 0)
        - COALESCE(cr.total_catalog_loss, 0))   AS net_profit_after_returns
FROM household_demographics AS hd
LEFT JOIN catalog_ret AS cr
       ON cr.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN store_ret AS sr
       ON sr.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN web_sales_agg AS ws
       ON ws.hd_demo_sk = hd.hd_demo_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100

WITH sales_agg AS (
       SELECT ss_hdemo_sk AS hd_demo_sk,
              SUM(ss_net_paid)      AS total_sales_net_paid,
              SUM(ss_net_profit)    AS total_sales_net_profit,
              COUNT(*)              AS sales_cnt
       FROM store_sales
       GROUP BY ss_hdemo_sk
   ),
   returns_agg AS (
       SELECT sr_hdemo_sk AS hd_demo_sk,
              SUM(sr_net_loss) AS total_store_return_net_loss,
              COUNT(*)         AS store_return_cnt
       FROM store_returns
       GROUP BY sr_hdemo_sk
   ),
   web_returns_agg AS (
       SELECT wr_refunded_hdemo_sk AS hd_demo_sk,
              SUM(wr_net_loss) AS total_web_return_net_loss,
              COUNT(*)         AS web_return_cnt
       FROM web_returns
       GROUP BY wr_refunded_hdemo_sk
   )
SELECT
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(SUM(s.total_sales_net_paid), 0)    AS total_sales_net_paid,
    COALESCE(SUM(s.total_sales_net_profit), 0)  AS total_sales_net_profit,
    COALESCE(SUM(r.total_store_return_net_loss), 0) AS total_store_return_net_loss,
    COALESCE(SUM(w.total_web_return_net_loss), 0)   AS total_web_return_net_loss,
    COALESCE(SUM(s.total_sales_net_paid), 0)
        - COALESCE(SUM(r.total_store_return_net_loss), 0)
        - COALESCE(SUM(w.total_web_return_net_loss), 0) AS net_revenue_after_returns,
    COALESCE(SUM(s.sales_cnt), 0)       AS sales_transactions,
    COALESCE(SUM(r.store_return_cnt), 0) AS store_return_transactions,
    COALESCE(SUM(w.web_return_cnt), 0)   AS web_return_transactions
FROM household_demographics hd
LEFT JOIN income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN sales_agg s
       ON s.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN returns_agg r
       ON r.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN web_returns_agg w
       ON w.hd_demo_sk = hd.hd_demo_sk
GROUP BY
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY net_revenue_after_returns DESC
LIMIT 100

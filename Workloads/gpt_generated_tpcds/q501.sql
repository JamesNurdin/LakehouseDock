WITH
    store_sales_agg AS (
        SELECT
            ss_hdemo_sk AS hd_demo_sk,
            SUM(ss_net_profit) AS store_sales_net_profit,
            COUNT(*) AS store_sales_transactions
        FROM store_sales
        GROUP BY ss_hdemo_sk
    ),
    store_returns_agg AS (
        SELECT
            sr_hdemo_sk AS hd_demo_sk,
            SUM(sr_net_loss) AS store_returns_net_loss,
            COUNT(*) AS store_returns_transactions
        FROM store_returns
        GROUP BY sr_hdemo_sk
    ),
    catalog_sales_agg AS (
        SELECT
            cs_bill_hdemo_sk AS hd_demo_sk,
            SUM(cs_net_profit) AS catalog_sales_net_profit,
            COUNT(*) AS catalog_sales_transactions
        FROM catalog_sales
        GROUP BY cs_bill_hdemo_sk
    ),
    web_returns_agg AS (
        SELECT
            wr_refunded_hdemo_sk AS hd_demo_sk,
            SUM(wr_net_loss) AS web_returns_net_loss,
            COUNT(*) AS web_returns_transactions
        FROM web_returns
        GROUP BY wr_refunded_hdemo_sk
    )
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    COALESCE(ss.store_sales_net_profit, 0) AS store_sales_net_profit,
    COALESCE(sr.store_returns_net_loss, 0) AS store_returns_net_loss,
    COALESCE(cs.catalog_sales_net_profit, 0) AS catalog_sales_net_profit,
    COALESCE(wr.web_returns_net_loss, 0) AS web_returns_net_loss,
    (COALESCE(ss.store_sales_net_profit, 0) + COALESCE(cs.catalog_sales_net_profit, 0) - COALESCE(sr.store_returns_net_loss, 0) - COALESCE(wr.web_returns_net_loss, 0)) AS overall_net_profit,
    COALESCE(ss.store_sales_transactions, 0) AS store_sales_transactions,
    COALESCE(sr.store_returns_transactions, 0) AS store_returns_transactions,
    COALESCE(cs.catalog_sales_transactions, 0) AS catalog_sales_transactions,
    COALESCE(wr.web_returns_transactions, 0) AS web_returns_transactions
FROM household_demographics hd
LEFT JOIN store_sales_agg ss ON ss.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN store_returns_agg sr ON sr.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN catalog_sales_agg cs ON cs.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN web_returns_agg wr ON wr.hd_demo_sk = hd.hd_demo_sk
ORDER BY overall_net_profit DESC
LIMIT 20

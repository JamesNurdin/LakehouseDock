WITH
    -- Aggregate store sales per household demographic
    store_sales_agg AS (
        SELECT
            ss_hdemo_sk,
            SUM(ss_net_paid_inc_tax) AS total_store_sales,
            SUM(ss_net_profit) AS total_store_profit
        FROM store_sales
        WHERE ss_quantity > 0
        GROUP BY ss_hdemo_sk
    ),
    -- Aggregate store returns per household demographic
    store_returns_agg AS (
        SELECT
            sr_hdemo_sk,
            SUM(sr_net_loss) AS total_store_returns_loss
        FROM store_returns
        GROUP BY sr_hdemo_sk
    ),
    -- Aggregate web sales per household demographic (using billing demographic)
    web_sales_agg AS (
        SELECT
            ws_bill_hdemo_sk AS hdemo_sk,
            SUM(ws_net_paid_inc_tax) AS total_web_sales,
            SUM(ws_net_profit) AS total_web_profit
        FROM web_sales
        WHERE ws_quantity > 0
        GROUP BY ws_bill_hdemo_sk
    ),
    -- Aggregate web returns per household demographic (using refunded demographic)
    web_returns_agg AS (
        SELECT
            wr_refunded_hdemo_sk AS hdemo_sk,
            SUM(wr_net_loss) AS total_web_returns_loss
        FROM web_returns
        GROUP BY wr_refunded_hdemo_sk
    ),
    -- Aggregate catalog returns per household demographic (using refunded demographic)
    catalog_returns_agg AS (
        SELECT
            cr_refunded_hdemo_sk AS hdemo_sk,
            SUM(cr_net_loss) AS total_catalog_returns_loss
        FROM catalog_returns
        GROUP BY cr_refunded_hdemo_sk
    ),
    -- Demographic details enriched with income band bounds
    demographics AS (
        SELECT
            hd.hd_demo_sk,
            hd.hd_income_band_sk,
            hd.hd_buy_potential,
            hd.hd_vehicle_count,
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),
    -- Combine all aggregates with demographics
    final AS (
        SELECT
            d.hd_buy_potential,
            d.hd_vehicle_count,
            d.ib_lower_bound,
            d.ib_upper_bound,
            COALESCE(ss.total_store_sales, 0) AS total_store_sales,
            COALESCE(ss.total_store_profit, 0) AS total_store_profit,
            COALESCE(sr.total_store_returns_loss, 0) AS total_store_returns_loss,
            COALESCE(ws.total_web_sales, 0) AS total_web_sales,
            COALESCE(ws.total_web_profit, 0) AS total_web_profit,
            COALESCE(wr.total_web_returns_loss, 0) AS total_web_returns_loss,
            COALESCE(cr.total_catalog_returns_loss, 0) AS total_catalog_returns_loss,
            (COALESCE(ss.total_store_profit, 0) + COALESCE(ws.total_web_profit, 0)
                - COALESCE(sr.total_store_returns_loss, 0)
                - COALESCE(wr.total_web_returns_loss, 0)
                - COALESCE(cr.total_catalog_returns_loss, 0)) AS net_contribution
        FROM demographics d
        LEFT JOIN store_sales_agg ss ON ss.ss_hdemo_sk = d.hd_demo_sk
        LEFT JOIN store_returns_agg sr ON sr.sr_hdemo_sk = d.hd_demo_sk
        LEFT JOIN web_sales_agg ws ON ws.hdemo_sk = d.hd_demo_sk
        LEFT JOIN web_returns_agg wr ON wr.hdemo_sk = d.hd_demo_sk
        LEFT JOIN catalog_returns_agg cr ON cr.hdemo_sk = d.hd_demo_sk
    )
SELECT
    final.hd_buy_potential,
    final.hd_vehicle_count,
    final.ib_lower_bound,
    final.ib_upper_bound,
    final.total_store_sales,
    final.total_store_profit,
    final.total_store_returns_loss,
    final.total_web_sales,
    final.total_web_profit,
    final.total_web_returns_loss,
    final.total_catalog_returns_loss,
    final.net_contribution,
    ROW_NUMBER() OVER (PARTITION BY final.ib_lower_bound ORDER BY final.net_contribution DESC) AS rank_within_income_band
FROM final
ORDER BY final.ib_lower_bound, rank_within_income_band

WITH
    catalog_return_agg AS (
        SELECT
            ib_income_band_sk,
            ib_lower_bound,
            ib_upper_bound,
            SUM(cr_net_loss) AS total_catalog_net_loss,
            COUNT(*) AS catalog_return_cnt
        FROM catalog_returns
        JOIN household_demographics
            ON catalog_returns.cr_refunded_hdemo_sk = household_demographics.hd_demo_sk
        JOIN income_band
            ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
        GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
    ),
    web_return_agg AS (
        SELECT
            ib_income_band_sk,
            ib_lower_bound,
            ib_upper_bound,
            SUM(wr_net_loss) AS total_web_return_net_loss,
            COUNT(*) AS web_return_cnt
        FROM web_returns
        JOIN household_demographics
            ON web_returns.wr_refunded_hdemo_sk = household_demographics.hd_demo_sk
        JOIN income_band
            ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
        GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
    ),
    web_sales_agg AS (
        SELECT
            ib_income_band_sk,
            ib_lower_bound,
            ib_upper_bound,
            SUM(ws_net_profit) AS total_web_sales_net_profit,
            COUNT(*) AS web_sales_cnt
        FROM web_sales
        JOIN household_demographics
            ON web_sales.ws_bill_hdemo_sk = household_demographics.hd_demo_sk
        JOIN income_band
            ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
        GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
    ),
    return_rate_agg AS (
        SELECT
            ib_income_band_sk,
            ib_lower_bound,
            ib_upper_bound,
            COUNT(*) AS returns_linked_to_sales_cnt
        FROM web_returns
        JOIN web_sales
            ON web_returns.wr_item_sk = web_sales.ws_item_sk
            AND web_returns.wr_order_number = web_sales.ws_order_number
        JOIN household_demographics
            ON web_sales.ws_bill_hdemo_sk = household_demographics.hd_demo_sk
        JOIN income_band
            ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
        GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
    )
SELECT
    COALESCE(cra.ib_lower_bound, wra.ib_lower_bound, wsa.ib_lower_bound, rra.ib_lower_bound) AS lower_bound,
    COALESCE(cra.ib_upper_bound, wra.ib_upper_bound, wsa.ib_upper_bound, rra.ib_upper_bound) AS upper_bound,
    COALESCE(cra.total_catalog_net_loss, 0) AS total_catalog_net_loss,
    COALESCE(cra.catalog_return_cnt, 0) AS catalog_return_cnt,
    COALESCE(wra.total_web_return_net_loss, 0) AS total_web_return_net_loss,
    COALESCE(wra.web_return_cnt, 0) AS web_return_cnt,
    COALESCE(wsa.total_web_sales_net_profit, 0) AS total_web_sales_net_profit,
    COALESCE(wsa.web_sales_cnt, 0) AS web_sales_cnt,
    COALESCE(rra.returns_linked_to_sales_cnt, 0) AS returns_linked_to_sales_cnt,
    (COALESCE(wsa.total_web_sales_net_profit, 0) - (COALESCE(cra.total_catalog_net_loss, 0) + COALESCE(wra.total_web_return_net_loss, 0))) AS net_profit_adjusted,
    CASE
        WHEN COALESCE(wsa.web_sales_cnt, 0) = 0 THEN 0
        ELSE CAST(COALESCE(rra.returns_linked_to_sales_cnt, 0) AS double) / COALESCE(wsa.web_sales_cnt, 0)
    END AS return_rate
FROM catalog_return_agg cra
FULL OUTER JOIN web_return_agg wra
    ON cra.ib_income_band_sk = wra.ib_income_band_sk
FULL OUTER JOIN web_sales_agg wsa
    ON COALESCE(cra.ib_income_band_sk, wra.ib_income_band_sk) = wsa.ib_income_band_sk
FULL OUTER JOIN return_rate_agg rra
    ON COALESCE(cra.ib_income_band_sk, wra.ib_income_band_sk, wsa.ib_income_band_sk) = rra.ib_income_band_sk
ORDER BY lower_bound

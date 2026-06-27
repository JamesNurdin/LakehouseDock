WITH sales_by_demo AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS num_sales
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
),
returns_by_demo AS (
    SELECT
        hd.hd_demo_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS num_returns
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_demo_sk
)
SELECT
    s.hd_income_band_sk,
    s.hd_buy_potential,
    s.hd_dep_count,
    s.hd_vehicle_count,
    s.total_sales,
    s.total_profit,
    s.num_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(r.num_returns, 0) AS num_returns,
    CASE
        WHEN s.total_sales > 0 THEN COALESCE(r.total_return_amount, 0) / s.total_sales
        ELSE NULL
    END AS return_to_sales_ratio
FROM sales_by_demo s
LEFT JOIN returns_by_demo r
    ON s.hd_demo_sk = r.hd_demo_sk
ORDER BY s.total_sales DESC
LIMIT 100

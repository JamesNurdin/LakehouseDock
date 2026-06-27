WITH store_sales_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS total_store_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
catalog_sales_agg AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(cs.cs_net_profit) AS total_catalog_net_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_catalog_customers
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
catalog_returns_agg AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(cr.cr_net_loss) AS total_return_net_loss,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_return_customers
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(ssa.total_store_net_profit, 0) AS total_store_net_profit,
    COALESCE(csa.total_catalog_net_profit, 0) AS total_catalog_net_profit,
    COALESCE(cra.total_return_net_loss, 0) AS total_return_net_loss,
    COALESCE(ssa.distinct_store_customers, 0) AS distinct_store_customers,
    COALESCE(csa.distinct_catalog_customers, 0) AS distinct_catalog_customers,
    COALESCE(cra.distinct_return_customers, 0) AS distinct_return_customers
FROM income_band ib
LEFT JOIN store_sales_agg ssa
    ON ib.ib_income_band_sk = ssa.ib_income_band_sk
LEFT JOIN catalog_sales_agg csa
    ON ib.ib_income_band_sk = csa.ib_income_band_sk
LEFT JOIN catalog_returns_agg cra
    ON ib.ib_income_band_sk = cra.ib_income_band_sk
ORDER BY ib.ib_income_band_sk

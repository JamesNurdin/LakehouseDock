WITH billing_metrics AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        'billing' AS demo_side
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_net_profit > 0
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
shipping_metrics AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        'shipping' AS demo_side
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_net_profit > 0
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
combined AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        total_net_profit,
        total_quantity,
        avg_net_profit,
        distinct_orders,
        demo_side
    FROM billing_metrics
    UNION ALL
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        total_net_profit,
        total_quantity,
        avg_net_profit,
        distinct_orders,
        demo_side
    FROM shipping_metrics
)
SELECT
    combined.ib_income_band_sk,
    combined.ib_lower_bound,
    combined.ib_upper_bound,
    combined.demo_side,
    combined.total_net_profit,
    combined.total_quantity,
    combined.avg_net_profit,
    combined.distinct_orders,
    combined.total_net_profit / NULLIF(combined.total_quantity, 0) AS profit_per_quantity,
    combined.total_net_profit / NULLIF(combined.distinct_orders, 0) AS profit_per_order,
    RANK() OVER (PARTITION BY combined.demo_side ORDER BY combined.total_net_profit DESC) AS profit_rank_by_side
FROM combined
ORDER BY combined.ib_lower_bound, combined.demo_side

WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_paid) AS total_paid,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_quantity > 0
      AND ib.ib_upper_bound >= 100000
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
),
returns_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(wr.wr_return_amt) AS total_return,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wr.wr_return_quantity > 0
      AND ib.ib_upper_bound >= 100000
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
)
SELECT
    customer_id,
    first_name,
    last_name,
    metric_type,
    metric_amount,
    ROW_NUMBER() OVER (PARTITION BY metric_type ORDER BY metric_amount DESC) AS metric_rank
FROM (
    SELECT
        c_customer_id AS customer_id,
        c_first_name AS first_name,
        c_last_name AS last_name,
        'sales' AS metric_type,
        total_paid AS metric_amount
    FROM sales_agg
    UNION ALL
    SELECT
        c_customer_id AS customer_id,
        c_first_name AS first_name,
        c_last_name AS last_name,
        'return' AS metric_type,
        total_net_loss AS metric_amount
    FROM returns_agg
) combined
ORDER BY metric_type, metric_rank
LIMIT 100

WITH store_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        'store' AS sales_channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 80000
      AND ib.ib_upper_bound <= 150000
    GROUP BY c.c_customer_id
),
catalog_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        'catalog' AS sales_channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS num_transactions
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 80000
      AND ib.ib_upper_bound <= 150000
    GROUP BY c.c_customer_id
)
SELECT *
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
) AS combined
ORDER BY total_sales DESC
LIMIT 100

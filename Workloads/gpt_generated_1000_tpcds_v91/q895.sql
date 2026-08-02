WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_count,
        CASE
            WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High'
            WHEN SUM(ss.ss_net_profit) > 5000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451400 AND 2452600
    GROUP BY
        c.c_customer_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
store_return_customers AS (
    SELECT DISTINCT c.c_customer_id
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451400 AND 2452600
),
web_return_customers AS (
    SELECT DISTINCT c.c_customer_id
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451400 AND 2452600
),
eligible_customers AS (
    SELECT
        s.c_customer_id,
        s.total_net_profit,
        s.profit_category,
        s.ib_lower_bound,
        s.ib_upper_bound
    FROM sales_summary s
    WHERE NOT EXISTS (
        SELECT 1 FROM store_return_customers r WHERE r.c_customer_id = s.c_customer_id
    )
    AND NOT EXISTS (
        SELECT 1 FROM web_return_customers w WHERE w.c_customer_id = s.c_customer_id
    )
    AND s.profit_category <> 'Low'
),
medium_profit_customers AS (
    SELECT
        ec.c_customer_id,
        ec.total_net_profit,
        ec.profit_category,
        ec.ib_lower_bound,
        ec.ib_upper_bound
    FROM eligible_customers ec
    WHERE ec.profit_category = 'Medium'
),
final_set AS (
    SELECT
        ec.c_customer_id,
        ec.total_net_profit,
        ec.profit_category,
        ec.ib_lower_bound,
        ec.ib_upper_bound
    FROM eligible_customers ec
    EXCEPT
    SELECT
        mc.c_customer_id,
        mc.total_net_profit,
        mc.profit_category,
        mc.ib_lower_bound,
        mc.ib_upper_bound
    FROM medium_profit_customers mc
)
SELECT
    f.c_customer_id,
    f.total_net_profit,
    f.profit_category,
    f.ib_lower_bound,
    f.ib_upper_bound
FROM final_set f
ORDER BY f.total_net_profit DESC
LIMIT 100

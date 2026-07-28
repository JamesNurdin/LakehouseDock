/*
  Goal: Identify the top customers (by total web return amount) who have a salutation of Mrs. or Ms., belong to households with at least 3 dependents, and fall in an income band whose lower bound is >= 50,000. Exclude any customer that ever had a return with zero amount, classify the total return amount as High or Low, and rank customers by that total.
*/
WITH aggregated AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        wp.wp_url,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS return_category
    FROM
        web_returns wr
        JOIN customer c
            ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
            ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        -- additional join to satisfy the rule between web_page and customer
        JOIN customer c2
            ON wp.wp_customer_sk = c2.c_customer_sk
    WHERE
        c.c_salutation IN ('Mrs.', 'Ms.')
        AND hd.hd_dep_count >= 3
        AND ib.ib_lower_bound >= 50000
        AND NOT EXISTS (
            SELECT 1
            FROM web_returns wr0
            WHERE wr0.wr_refunded_customer_sk = c.c_customer_sk
              AND wr0.wr_return_amt = 0.00
        )
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        wp.wp_url
)
SELECT
    a.c_customer_sk,
    a.c_first_name,
    a.c_last_name,
    a.wp_url,
    a.total_return_amt,
    a.total_net_loss,
    a.return_category,
    RANK() OVER (ORDER BY a.total_return_amt DESC) AS return_rank
FROM aggregated a
ORDER BY return_rank
LIMIT 100

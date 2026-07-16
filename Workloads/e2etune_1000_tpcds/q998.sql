WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cs.cs_net_paid_inc_ship) AS total_sales_paid,
        COUNT(*) AS sales_txn_cnt
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship > 2000
      AND cs.cs_quantity > 10
      AND cs.cs_ship_mode_sk IN (1, 5, 18)
    GROUP BY cs.cs_bill_customer_sk
),
store_ret_agg AS (
    SELECT
        sr.sr_customer_sk AS cust_sk,
        SUM(sr.sr_net_loss) AS total_store_loss,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        COUNT(*) AS store_ret_cnt
    FROM store_returns sr
    WHERE sr.sr_return_amt > 100
    GROUP BY sr.sr_customer_sk
),
web_ret_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS cust_sk,
        SUM(wr.wr_net_loss) AS total_web_loss,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        COUNT(*) AS web_ret_cnt
    FROM web_returns wr
    WHERE wr.wr_return_amt > 100
    GROUP BY wr.wr_refunded_customer_sk
)
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(st.total_store_loss, 0) AS total_store_loss,
    COALESCE(wt.total_web_loss, 0) AS total_web_loss,
    (COALESCE(s.total_sales_profit, 0) - COALESCE(st.total_store_loss, 0) - COALESCE(wt.total_web_loss, 0)) AS net_contribution,
    RANK() OVER (ORDER BY (COALESCE(s.total_sales_profit, 0) - COALESCE(st.total_store_loss, 0) - COALESCE(wt.total_web_loss, 0)) DESC) AS sales_rank
FROM customer c
LEFT JOIN sales_agg s   ON c.c_customer_sk = s.cust_sk
LEFT JOIN store_ret_agg st ON c.c_customer_sk = st.cust_sk
LEFT JOIN web_ret_agg wt ON c.c_customer_sk = wt.cust_sk
WHERE (COALESCE(s.total_sales_profit, 0) - COALESCE(st.total_store_loss, 0) - COALESCE(wt.total_web_loss, 0)) > 0
ORDER BY net_contribution DESC
LIMIT 20

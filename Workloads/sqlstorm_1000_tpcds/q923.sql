WITH
sales_all AS (
    SELECT cs_bill_customer_sk AS cust_sk,
           cs_sold_date_sk AS date_sk,
           cs_net_paid_inc_tax AS net_paid,
           cs_ext_sales_price AS ext_sales,
           cs_quantity AS quantity,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_customer_sk AS cust_sk,
           ss_sold_date_sk AS date_sk,
           ss_net_paid_inc_tax AS net_paid,
           ss_ext_sales_price AS ext_sales,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS cust_sk,
           ws_sold_date_sk AS date_sk,
           ws_net_paid_inc_tax AS net_paid,
           ws_ext_sales_price AS ext_sales,
           ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
),
customer_sales AS (
    SELECT
        s.cust_sk,
        d.d_year,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.ext_sales) AS total_ext_sales,
        SUM(s.quantity) AS total_quantity,
        COUNT(*) AS transaction_count
    FROM sales_all s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY s.cust_sk, d.d_year
),
returns_all AS (
    SELECT cr_returning_customer_sk AS cust_sk,
           cr_returned_date_sk AS date_sk,
           cr_return_amt_inc_tax AS return_amount,
           cr_return_quantity AS return_qty,
           'catalog' AS channel
    FROM catalog_returns
    UNION ALL
    SELECT sr_customer_sk AS cust_sk,
           sr_returned_date_sk AS date_sk,
           sr_return_amt_inc_tax AS return_amount,
           sr_return_quantity AS return_qty,
           'store' AS channel
    FROM store_returns
    UNION ALL
    SELECT wr_refunded_customer_sk AS cust_sk,
           wr_returned_date_sk AS date_sk,
           wr_return_amt_inc_tax AS return_amount,
           wr_return_quantity AS return_qty,
           'web' AS channel
    FROM web_returns
),
customer_returns AS (
    SELECT
        r.cust_sk,
        d.d_year,
        SUM(r.return_amount) AS total_return_amount,
        SUM(r.return_qty) AS total_return_qty,
        COUNT(*) AS return_transaction_count
    FROM returns_all r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    GROUP BY r.cust_sk, d.d_year
),
customer_net AS (
    SELECT
        COALESCE(cs.cust_sk, cr.cust_sk) AS cust_sk,
        COALESCE(cs.d_year, cr.d_year) AS d_year,
        COALESCE(cs.total_net_paid, 0) AS total_net_paid,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cs.total_net_paid, 0) - COALESCE(cr.total_return_amount, 0) AS net_profit,
        COALESCE(cs.transaction_count, 0) AS transaction_count,
        COALESCE(cr.return_transaction_count, 0) AS return_transaction_count
    FROM customer_sales cs
    FULL OUTER JOIN customer_returns cr
      ON cs.cust_sk = cr.cust_sk
      AND cs.d_year = cr.d_year
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
        COALESCE(cd.cd_gender, 'UNKNOWN') AS gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CONCAT('CUST', LPAD(CAST(c.c_customer_sk AS VARCHAR), 8, '0')) AS cust_code
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN income_band ib ON cd.cd_dep_count = ib.ib_income_band_sk
),
ranked_customers AS (
    SELECT
        cn.cust_sk,
        cn.d_year,
        cn.net_profit,
        ci.full_name,
        ci.cust_code,
        ci.gender,
        RANK() OVER (PARTITION BY cn.d_year ORDER BY cn.net_profit DESC) AS profit_rank,
        AVG(cn.net_profit) OVER (PARTITION BY cn.d_year) AS avg_year_profit,
        cn.net_profit - AVG(cn.net_profit) OVER (PARTITION BY cn.d_year) AS profit_vs_avg,
        CASE
            WHEN cn.net_profit > (SELECT AVG(net_profit) FROM customer_net WHERE d_year = cn.d_year) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS profit_category,
        CASE
            WHEN ci.ib_lower_bound IS NULL OR ci.ib_upper_bound IS NULL THEN 'Income Unknown'
            WHEN cn.net_profit > 10000 THEN 'High Profit'
            ELSE 'Standard'
        END AS profit_tier,
        ROUND(cn.net_profit / NULLIF(cn.total_net_paid, 0), 4) AS net_profit_margin
    FROM customer_net cn
    LEFT JOIN customer_info ci ON cn.cust_sk = ci.c_customer_sk
),
final_set AS (
    SELECT
        cust_sk,
        d_year,
        profit_rank,
        full_name,
        cust_code,
        gender,
        net_profit,
        profit_vs_avg,
        profit_category,
        profit_tier,
        net_profit_margin
    FROM ranked_customers
    WHERE profit_rank <= 10
    UNION ALL
    SELECT
        NULL AS cust_sk,
        dy.d_year,
        NULL AS profit_rank,
        'No Sales' AS full_name,
        NULL AS cust_code,
        NULL AS gender,
        0 AS net_profit,
        0 AS profit_vs_avg,
        'No Data' AS profit_category,
        'No Data' AS profit_tier,
        NULL AS net_profit_margin
    FROM (SELECT DISTINCT d_year FROM date_dim WHERE d_year BETWEEN 1998 AND 2002) dy
    WHERE NOT EXISTS (
        SELECT 1 FROM ranked_customers rc WHERE rc.d_year = dy.d_year AND rc.profit_rank <= 10
    )
)
SELECT *
FROM final_set
ORDER BY d_year, profit_rank NULLS LAST, net_profit DESC

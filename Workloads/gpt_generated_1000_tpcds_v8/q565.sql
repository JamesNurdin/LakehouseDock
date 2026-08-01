WITH
    cs_sample AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    sr_sample AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (20)
    ),
    cs_agg AS (
        SELECT
            cs.cs_bill_customer_sk AS cust_sk,
            cs.cs_sold_time_sk AS time_sk,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_quantity) AS total_quantity
        FROM cs_sample cs
        GROUP BY cs.cs_bill_customer_sk, cs.cs_sold_time_sk
    ),
    sr_agg AS (
        SELECT
            sr.sr_customer_sk AS cust_sk,
            sr.sr_return_time_sk AS time_sk,
            SUM(sr.sr_return_amt) AS total_return_amt,
            SUM(sr.sr_return_quantity) AS total_return_qty
        FROM sr_sample sr
        GROUP BY sr.sr_customer_sk, sr.sr_return_time_sk
    ),
    customers_with_sales AS (
        SELECT DISTINCT cust_sk FROM cs_agg
    ),
    customers_with_returns AS (
        SELECT DISTINCT cust_sk FROM sr_agg
    ),
    customers_returns_not_sales AS (
        SELECT cust_sk FROM customers_with_returns
        EXCEPT
        SELECT cust_sk FROM customers_with_sales
    )
SELECT
    c.c_customer_id,
    ca1.ca_city,
    cd1.cd_gender,
    hd1.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    r.r_reason_desc,
    t_sales.t_hour AS sale_hour,
    t_return.t_hour AS return_hour,
    COALESCE(cs_agg.total_sales, 0) AS total_sales,
    COALESCE(sr_agg.total_return_amt, 0) AS total_return_amount,
    COALESCE(cs_agg.total_quantity, 0) AS total_quantity_sold,
    COALESCE(sr_agg.total_return_qty, 0) AS total_quantity_returned
FROM
    customers_returns_not_sales crns
    LEFT JOIN customer c
        ON c.c_customer_sk = crns.cust_sk
    FULL OUTER JOIN cs_agg
        ON cs_agg.cust_sk = c.c_customer_sk
    FULL OUTER JOIN sr_agg
        ON sr_agg.cust_sk = c.c_customer_sk
    LEFT JOIN customer_address ca1
        ON ca1.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd1
        ON cd1.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN household_demographics hd1
        ON hd1.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_band ib
        ON ib.ib_income_band_sk = hd1.hd_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    LEFT JOIN time_dim t_return
        ON t_return.t_time_sk = sr.sr_return_time_sk
    LEFT JOIN time_dim t_sales
        ON t_sales.t_time_sk = cs_agg.time_sk
WHERE EXISTS (
    SELECT 1
    FROM reason r2
    WHERE r2.r_reason_sk = sr.sr_reason_sk
      AND r2.r_reason_desc LIKE '%defect%'
)
ORDER BY total_sales DESC
LIMIT 100

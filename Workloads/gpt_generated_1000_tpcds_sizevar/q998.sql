WITH
joined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        c.c_customer_id,
        ca_r.ca_state,
        d_ret.d_year,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS amt_cat,
        lr.total_ret_amt
    FROM catalog_returns cr
    -- date of the catalog return
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    -- refunded (or returning) customer
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    -- address of the returning customer
    JOIN customer_address ca_r ON cr.cr_returning_addr_sk = ca_r.ca_address_sk
    -- lateral sub‑query that totals all catalog returns for the same customer
    CROSS JOIN LATERAL (
        SELECT SUM(cr2.cr_return_amount) AS total_ret_amt
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
    ) AS lr
    -- additional date joins via different surrogate keys in CUSTOMER
    JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    -- current address of the customer
    JOIN customer_address ca_c ON c.c_current_addr_sk = ca_c.ca_address_sk
    -- store‑return side (joined through the same CUSTOMER)
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    -- web‑return side (joined through the same CUSTOMER)
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN customer_address ca_wr ON wr.wr_returning_addr_sk = ca_wr.ca_address_sk
    WHERE d_ret.d_year = 2001
),
sel1 AS (
    SELECT
        amt_cat,
        COUNT(DISTINCT c_customer_id) AS cust_cnt,
        SUM(cr_return_amount) AS sum_cr_amt,
        SUM(total_ret_amt) AS sum_total_ret
    FROM joined
    GROUP BY amt_cat
),
sel2 AS (
    SELECT
        CASE WHEN cr_return_amount > 200 THEN 'Very High' ELSE 'Other' END AS amt_cat,
        COUNT(DISTINCT c_customer_id) AS cust_cnt,
        SUM(cr_return_amount) AS sum_cr_amt,
        SUM(total_ret_amt) AS sum_total_ret
    FROM joined
    WHERE cr_return_amount BETWEEN 50 AND 150
    GROUP BY CASE WHEN cr_return_amount > 200 THEN 'Very High' ELSE 'Other' END
),
unioned AS (
    SELECT * FROM sel1
    UNION
    SELECT * FROM sel2
),
exclude_set AS (
    SELECT
        CASE WHEN cr_return_amount > 300 THEN 'Extreme' ELSE 'Other' END AS amt_cat,
        COUNT(DISTINCT c_customer_id) AS cust_cnt,
        SUM(cr_return_amount) AS sum_cr_amt,
        SUM(total_ret_amt) AS sum_total_ret
    FROM joined
    WHERE cr_return_amount > 400
    GROUP BY CASE WHEN cr_return_amount > 300 THEN 'Extreme' ELSE 'Other' END
)
SELECT *
FROM unioned
EXCEPT
SELECT *
FROM exclude_set
LIMIT 100

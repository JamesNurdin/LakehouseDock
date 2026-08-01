WITH top_customer_sales AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_ext_sales_price > (
        SELECT MAX(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = 20000101
    )
      AND cs.cs_item_sk IN (
        SELECT i2.i_item_sk
        FROM item i2
        WHERE i2.i_category = 'Electronics'
    )
),
sales_union AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_ext_sales_price AS amount,
        cs.cs_sold_date_sk AS date_sk
    FROM catalog_sales cs
    JOIN top_customer_sales tcs
        ON cs.cs_bill_customer_sk = tcs.cs_bill_customer_sk
        AND cs.cs_item_sk = tcs.cs_item_sk
    WHERE tcs.sales_rank <= 5

    UNION ALL

    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_ext_sales_price AS amount,
        ss.ss_sold_date_sk AS date_sk
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_ext_sales_price > (
        SELECT MIN(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_sold_date_sk = 20000101
    )
      AND i.i_category = 'Electronics'
),
return_keys AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_return_amt AS amount,
        sr.sr_returned_date_sk AS date_sk
    FROM store_returns sr
    WHERE sr.sr_customer_sk IN (
        SELECT cs.cs_bill_customer_sk
        FROM catalog_sales cs
        WHERE cs.cs_ext_sales_price > 500
    )
)
SELECT
    su.customer_sk,
    su.item_sk,
    su.amount,
    su.date_sk
FROM sales_union su
WHERE (su.customer_sk, su.item_sk) NOT IN (
    SELECT rk.customer_sk, rk.item_sk
    FROM return_keys rk
)
EXCEPT
SELECT
    cs.cs_bill_customer_sk,
    cs.cs_item_sk,
    cs.cs_ext_sales_price,
    cs.cs_sold_date_sk
FROM catalog_sales cs
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cs.cs_ext_sales_price < 0
LIMIT 100

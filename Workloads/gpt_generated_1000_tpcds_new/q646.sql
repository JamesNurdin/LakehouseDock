WITH sampled_catalog AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)   -- sample approximately 10% of rows
    WHERE cs.cs_ext_sales_price > 500
),
full_store AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_ext_sales_price,
        sr.sr_return_quantity,
        sr.sr_return_amt
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
)
SELECT
    cs.cs_order_number            AS order_number,
    d.d_year,
    i.i_category,
    cs.cs_ext_sales_price        AS sales_price,
    (
        SELECT COALESCE(SUM(cr.cr_return_amount), 0)
        FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
    )                           AS total_return_amount
FROM sampled_catalog cs
JOIN date_dim d      ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i          ON cs.cs_item_sk = i.i_item_sk
WHERE d.d_year = 2001

UNION ALL

SELECT
    fs.ss_ticket_number          AS order_number,
    d2.d_year,
    i2.i_category,
    COALESCE(fs.ss_ext_sales_price, 0) AS sales_price,
    (
        SELECT COALESCE(SUM(sr2.sr_return_amt), 0)
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = fs.ss_ticket_number
    )                           AS total_return_amount
FROM full_store fs
JOIN date_dim d2    ON fs.ss_sold_date_sk = d2.d_date_sk
JOIN item i2        ON fs.ss_item_sk = i2.i_item_sk
WHERE d2.d_year = 2001

ORDER BY order_number
LIMIT 100

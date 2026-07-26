WITH sales_qtr AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_ticket_number,
        ss.ss_sales_price,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_fy_quarter_seq = (
        SELECT d_fy_quarter_seq FROM date_dim WHERE d_year = 2022 AND d_quarter_name = 'Q2' LIMIT 1
    )
),
returns_qtr AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_ticket_number,
        sr.sr_refunded_cash,
        sr.sr_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_fy_quarter_seq = (
        SELECT d_fy_quarter_seq FROM date_dim WHERE d_year = 2022 AND d_quarter_name = 'Q2' LIMIT 1
    )
)
SELECT
    cust.customer_sk,
    cust.total_sales_qty,
    cust.total_sales_amount,
    ret.total_returns_qty,
    ret.total_returns_amount,
    cust.avg_sale_price,
    ret.avg_return_amount,
    CASE
        WHEN cust.avg_sale_price = 0 THEN NULL
        ELSE ret.avg_return_amount / cust.avg_sale_price
    END AS return_to_sale_ratio,
    CASE
        WHEN ret.total_returns_qty > 20 THEN 'Heavy Returner'
        WHEN ret.total_returns_qty BETWEEN 10 AND 20 THEN 'Moderate Returner'
        ELSE 'Light Returner'
    END AS return_category,
    DENSE_RANK() OVER (ORDER BY ret.total_returns_qty DESC) AS return_qty_rank
FROM (
    SELECT
        s.ss_customer_sk AS customer_sk,
        SUM(s.ss_quantity) AS total_sales_qty,
        SUM(s.ss_sales_price * s.ss_quantity) AS total_sales_amount,
        AVG(s.ss_sales_price) AS avg_sale_price
    FROM sales_qtr s
    GROUP BY s.ss_customer_sk
) cust
JOIN (
    SELECT
        r.sr_customer_sk,
        SUM(r.sr_return_quantity) AS total_returns_qty,
        SUM(r.sr_refunded_cash) AS total_returns_amount,
        AVG(r.sr_refunded_cash) AS avg_return_amount
    FROM returns_qtr r
    GROUP BY r.sr_customer_sk
) ret ON cust.customer_sk = ret.sr_customer_sk
WHERE ret.total_returns_qty > 0
ORDER BY return_qty_rank
LIMIT 10

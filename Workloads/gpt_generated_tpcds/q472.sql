WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid,
        cs.cs_order_number
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount
    FROM catalog_returns cr
)
SELECT
    i.i_category,
    d.d_year,
    d.d_month_seq,
    SUM(s.cs_net_paid) AS total_sales_amount,
    SUM(COALESCE(r.cr_return_amount, 0)) AS total_return_amount,
    SUM(s.cs_net_paid) - SUM(COALESCE(r.cr_return_amount, 0)) AS net_revenue,
    SUM(s.cs_quantity) AS total_quantity_sold,
    SUM(COALESCE(r.cr_return_quantity, 0)) AS total_quantity_returned,
    AVG(s.cs_ext_discount_amt) AS avg_discount_amount,
    AVG(s.cs_ext_ship_cost) AS avg_ship_cost,
    COUNT(DISTINCT s.cs_bill_customer_sk) AS distinct_customers
FROM sales s
JOIN item i
    ON s.cs_item_sk = i.i_item_sk
JOIN date_dim d
    ON s.cs_sold_date_sk = d.d_date_sk
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
    AND s.cs_item_sk = r.cr_item_sk
WHERE d.d_year = 2001
GROUP BY i.i_category, d.d_year, d.d_month_seq
ORDER BY i.i_category, d.d_year, d.d_month_seq

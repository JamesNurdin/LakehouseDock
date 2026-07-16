WITH
    sales_agg AS (
        SELECT
            d.d_year,
            c.c_customer_id,
            i.i_category,
            i.i_class,
            SUM(cs.cs_net_paid) AS total_sales,
            SUM(cs.cs_ext_discount_amt) AS total_discount,
            SUM(cs.cs_ext_tax) AS total_tax,
            COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
            COUNT(*) AS transaction_count
        FROM
            catalog_sales cs
            JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
            JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
            JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE
            d.d_year BETWEEN 1999 AND 2001
            AND i.i_category = 'Sports'
        GROUP BY
            d.d_year,
            c.c_customer_id,
            i.i_category,
            i.i_class
    ),
    returns_agg AS (
        SELECT
            d.d_year,
            c.c_customer_id,
            i.i_category,
            i.i_class,
            SUM(cr.cr_return_amount) AS total_return_amount,
            SUM(cr.cr_fee) AS total_return_fee,
            COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
        FROM
            catalog_returns cr
            JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
            JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
            JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE
            d.d_year BETWEEN 1999 AND 2001
            AND i.i_category = 'Sports'
        GROUP BY
            d.d_year,
            c.c_customer_id,
            i.i_category,
            i.i_class
    )
SELECT
    s.d_year,
    s.c_customer_id,
    s.i_category,
    s.i_class,
    s.total_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales,
    s.total_discount,
    s.total_tax,
    s.distinct_orders,
    s.transaction_count,
    RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rank
FROM
    sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year
        AND s.c_customer_id = r.c_customer_id
        AND s.i_category = r.i_category
        AND s.i_class = r.i_class
WHERE
    s.total_sales > 1000
ORDER BY
    s.d_year,
    net_sales DESC
LIMIT 100

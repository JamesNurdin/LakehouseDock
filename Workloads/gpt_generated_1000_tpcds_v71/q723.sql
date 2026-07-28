WITH recent_dates AS (
    SELECT DISTINCT d_date_sk, d_year
    FROM date_dim
    WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT
    customer_sk,
    sales_year,
    total_sales,
    distinct_transactions,
    sales_rank,
    avg_metric
FROM (
    -- Catalog sales side
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        dd.d_year AS sales_year,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_transactions,
        ROW_NUMBER() OVER (PARTITION BY dd.d_year ORDER BY SUM(cs.cs_net_paid_inc_tax) DESC) AS sales_rank,
        (
            SELECT AVG(cr.cr_return_amount)
            FROM catalog_returns cr
            JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
        ) AS avg_metric
    FROM catalog_sales cs
    JOIN recent_dates rd ON cs.cs_sold_date_sk = rd.d_date_sk
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
    )
    GROUP BY cs.cs_bill_customer_sk, dd.d_year

    UNION ALL

    -- Store sales side
    SELECT
        ss.ss_customer_sk AS customer_sk,
        dd.d_year AS sales_year,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_transactions,
        ROW_NUMBER() OVER (PARTITION BY dd.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank,
        (
            SELECT AVG(inv.inv_quantity_on_hand)
            FROM inventory inv
            JOIN recent_dates rd2 ON inv.inv_date_sk = rd2.d_date_sk
        ) AS avg_metric
    FROM store_sales ss
    JOIN recent_dates rd ON ss.ss_sold_date_sk = rd.d_date_sk
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM date_dim d_hol
        WHERE d_hol.d_date_sk = ss.ss_sold_date_sk
          AND d_hol.d_holiday = 'Y'
    )
    GROUP BY ss.ss_customer_sk, dd.d_year
) AS combined
ORDER BY sales_year, total_sales DESC

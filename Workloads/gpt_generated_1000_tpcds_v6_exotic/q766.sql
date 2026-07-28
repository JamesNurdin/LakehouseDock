WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_catalog_page_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        d.d_year,
        sm.sm_type,
        cp.cp_type,
        cp.cp_description,
        c.c_email_address,
        concat(cp.cp_type, '-', sm.sm_type) AS sales_channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_email_address LIKE '%@example.com'
      AND regexp_like(cp.cp_description, '.*(TV|Phone).*')
)
SELECT
    COALESCE(CAST(s.year AS VARCHAR), 'All Years') AS year,
    COALESCE(s.sales_channel, 'All Channels') AS sales_channel,
    SUM(s.total_paid) AS total_paid,
    SUM(s.total_profit) AS total_profit,
    AVG(s.avg_discount) AS avg_discount
FROM (
    SELECT
        fs.d_year AS year,
        fs.sales_channel,
        fs.cs_net_paid AS total_paid,
        fs.cs_net_profit AS total_profit,
        fs.cs_ext_discount_amt AS avg_discount
    FROM filtered_sales fs
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = fs.cs_order_number
    )
) s
GROUP BY ROLLUP (s.year, s.sales_channel)
ORDER BY s.year, s.sales_channel

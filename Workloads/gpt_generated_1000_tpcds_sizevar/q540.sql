WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_coupon_amt) AS total_coupon,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    WHERE ss.ss_net_paid_inc_tax > 1000
    GROUP BY ss.ss_store_sk, ss.ss_ticket_number, ss.ss_sold_date_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY SUM(sales_agg.total_net_paid) DESC) AS row_num,
    s.s_store_id,
    s.s_division_id,
    CASE WHEN s.s_tax_percentage > 0.07 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    c.c_customer_id,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_loss,
    SUM(sales_agg.total_net_paid) AS total_sales,
    AVG(sales_agg.total_coupon) AS avg_coupon,
    SUM(sr.sr_return_quantity) AS total_return_qty
FROM sales_agg
JOIN store s
    ON sales_agg.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
    AND sr.sr_ticket_number = sales_agg.ss_ticket_number
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    s.s_division_id = 1
    AND s.s_tax_percentage = 0.06
    AND wp.wp_max_ad_count = 2
    AND cr.cr_return_amount > 50
    AND sr.sr_return_amt > 20
    AND c.c_birth_year = 1970
    AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_max_ad_count > 3
    )
GROUP BY
    s.s_store_id,
    s.s_division_id,
    CASE WHEN s.s_tax_percentage > 0.07 THEN 'HighTax' ELSE 'LowTax' END,
    c.c_customer_id
ORDER BY total_sales DESC
LIMIT 100

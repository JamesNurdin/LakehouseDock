WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        cp.cp_department,
        r.r_reason_desc,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        AVG(CASE WHEN cs.cs_coupon_amt > 0 THEN cs.cs_coupon_amt ELSE NULL END) AS avg_coupon_amount,
        SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_quantity ELSE 0 END) AS total_return_qty,
        MAX(ss.ss_net_profit) AS max_store_profit,
        MIN(ss.ss_net_profit) AS min_store_profit
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
            AND cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN inventory i ON i.inv_date_sk = d.d_date_sk
        JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        ws.web_company_id = 3
        AND ws.web_gmt_offset = -5.00
        AND cs.cs_list_price > 100
        AND cp.cp_department = 'Electronics'
        AND hd.hd_buy_potential = '5001-10000'
        AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_customer_sk = c.c_customer_sk
                AND wp.wp_type = 'Home'
        )
    GROUP BY
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        cp.cp_department,
        r.r_reason_desc
    HAVING
        SUM(cs.cs_ext_sales_price) > 10000
        AND COUNT(DISTINCT cs.cs_order_number) >= 5
)
SELECT
    d_year,
    d_month_seq,
    c_customer_id,
    cp_department,
    r_reason_desc,
    total_sales,
    total_discount,
    total_return_amount,
    order_count,
    avg_coupon_amount,
    total_return_qty,
    max_store_profit,
    min_store_profit
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100

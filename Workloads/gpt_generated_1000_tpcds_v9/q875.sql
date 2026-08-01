WITH ss_agg AS (
    SELECT
        ss.ss_addr_sk,
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        AVG(ss.ss_coupon_amt) AS avg_coupon_amt
    FROM store_sales ss
    WHERE ss.ss_ext_sales_price > 1000
      AND ss.ss_quantity >= 1
      AND ss.ss_coupon_amt BETWEEN 0 AND 2000
      AND ss.ss_promo_sk IN (1413, 550, 1160)
    GROUP BY ss.ss_addr_sk, ss.ss_store_sk
)
SELECT
    s.s_store_name,
    s.s_state,
    ca.ca_city,
    cp.cp_department,
    r.r_reason_desc,
    ss_agg.total_sales,
    ss_agg.total_qty,
    ss_agg.total_discount,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss_agg.total_sales DESC) AS sales_rank,
    AVG(ss_agg.total_sales) OVER (
        PARTITION BY s.s_store_name
        ORDER BY ss_agg.total_sales DESC
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_sales,
    (SELECT MAX(cr2.cr_return_amount) FROM catalog_returns cr2) AS max_return_amount
FROM ss_agg
JOIN customer_address ca
    ON ss_agg.ss_addr_sk = ca.ca_address_sk
JOIN store s
    ON ss_agg.ss_store_sk = s.s_store_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE
    s.s_state = 'CA'
    AND ca.ca_country = 'United States'
    AND cp.cp_type = 'A'
    AND r.r_reason_desc NOT LIKE '%unauthorized%'
    AND cr.cr_return_amount > 50
    AND cr.cr_return_tax <= 10
    AND s.s_rec_start_date >= DATE '1999-01-01'
    AND s.s_rec_end_date <= DATE '2002-12-31'
ORDER BY ss_agg.total_sales DESC
LIMIT 100

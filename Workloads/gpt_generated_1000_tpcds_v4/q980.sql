WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_ext_ship_cost,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid,
        cs.cs_order_number
    FROM catalog_sales cs
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    cp.cp_department,
    s.s_store_name,
    COUNT(DISTINCT sd.cs_order_number) AS order_cnt,
    SUM(sd.cs_net_paid) AS total_net_paid,
    AVG(sd.cs_ext_ship_cost) AS avg_ship_cost,
    MIN(sd.cs_ext_discount_amt) AS min_discount,
    MAX(sr.sr_return_amt) AS max_return_amount
FROM sales_data sd
JOIN catalog_page cp
    ON sd.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON sd.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON sd.cs_sold_date_sk = d_sold.d_date_sk
JOIN customer c
    ON sd.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sd.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sd.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
WHERE
    d_sold.d_year = 2001
    AND cp.cp_catalog_number IN (6, 11, 13)
    AND p.p_discount_active = 'Y'
    AND cd.cd_gender = 'F'
    AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_type = 'Home'
          AND wp.wp_char_count > 1000
    )
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    cp.cp_department,
    s.s_store_name
ORDER BY
    total_net_paid DESC,
    order_cnt DESC
LIMIT 100

WITH joined_data AS (
    SELECT
        d.d_year,
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_state AS customer_state,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_id,
        cr.cr_return_amount,
        r.r_reason_desc,
        wr.wr_return_amt
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound > 50000
)
SELECT
    d_year,
    s_store_id,
    s_state,
    c_customer_id,
    customer_state,
    ib_lower_bound,
    ib_upper_bound,
    cp_department,
    sm_type,
    w_warehouse_id,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    CASE
        WHEN SUM(cs_ext_sales_price) > 500000 THEN 'Gold'
        WHEN SUM(cs_ext_sales_price) > 200000 THEN 'Silver'
        ELSE 'Bronze'
    END AS sales_tier,
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_order_number = joined_data.cs_order_number) AS avg_return_amount,
    ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
FROM joined_data
GROUP BY
    d_year,
    s_store_id,
    s_state,
    c_customer_id,
    customer_state,
    ib_lower_bound,
    ib_upper_bound,
    cp_department,
    sm_type,
    w_warehouse_id,
    s_store_sk,
    cs_order_number
ORDER BY total_sales DESC
LIMIT 100

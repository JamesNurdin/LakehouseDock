WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        ca.ca_state,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        w.w_warehouse_name,
        cp.cp_department,
        i.i_brand,
        i.i_item_id,
        i.i_current_price,
        ss.ss_net_paid,
        cs.cs_net_paid,
        sr.sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ss.ss_net_paid + COALESCE(cs.cs_net_paid, 0) DESC) AS sales_rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk AND cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_site ws ON d.d_date_sk = ws.web_open_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND c.c_preferred_cust_flag = 'Y'
      AND hd.hd_buy_potential = '5001-10000'
      AND ib.ib_upper_bound >= 120000
      AND r.r_reason_desc LIKE '%color%'
      AND cp.cp_department = 'Sports'
      AND w.w_state = 'CA'
)
SELECT
    fc.c_customer_id,
    fc.c_first_name,
    fc.c_last_name,
    fc.c_preferred_cust_flag,
    fc.ca_state,
    fc.hd_buy_potential,
    fc.ib_upper_bound,
    fc.w_warehouse_name,
    fc.cp_department,
    fc.i_brand,
    fc.i_item_id,
    fc.i_current_price,
    fc.sales_rank,
    CASE
        WHEN fc.sr_return_amt IS NOT NULL THEN 'Returned'
        ELSE 'No Return'
    END AS return_status,
    (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_brand = 'Brand#12') AS avg_brand_price
FROM filtered_customers fc
ORDER BY fc.sales_rank
LIMIT 100

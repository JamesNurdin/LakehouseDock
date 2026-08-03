WITH store_ret_agg AS (
        SELECT
            sr_item_sk,
            SUM(sr_return_amt) AS total_store_return,
            COUNT(*) AS cnt_store_return
        FROM store_returns
        GROUP BY sr_item_sk
    ),
    web_ret_agg AS (
        SELECT
            wr_item_sk,
            SUM(wr_return_amt) AS total_web_return,
            COUNT(*) AS cnt_web_return
        FROM web_returns
        GROUP BY wr_item_sk
    )
SELECT
    cp.cp_department,
    i.i_brand,
    sm.sm_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT c_bill.c_customer_id) AS distinct_customers,
    SUM(cs.cs_ext_sales_price) AS sum_sales,
    SUM(sra.total_store_return) AS sum_store_return,
    SUM(wra.total_web_return) AS sum_web_return,
    brand_max.max_price_for_brand
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_ret_agg sra
    ON sra.sr_item_sk = cs.cs_item_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = cs.cs_item_sk
   AND sr.sr_customer_sk = c_bill.c_customer_sk
LEFT JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
LEFT JOIN web_ret_agg wra
    ON wra.wr_item_sk = cs.cs_item_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = cs.cs_item_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
JOIN customer c_refunded
    ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
    ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
LEFT JOIN LATERAL (
        SELECT MAX(i2.i_current_price) AS max_price_for_brand
        FROM item i2
        WHERE i2.i_brand = i.i_brand
    ) AS brand_max ON TRUE
WHERE EXISTS (
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_state = ca_bill.ca_state
          AND ca2.ca_zip = ca_bill.ca_zip
          AND ca2.ca_address_sk <> ca_bill.ca_address_sk
    )
GROUP BY GROUPING SETS (
        (cp.cp_department),
        (i.i_brand),
        (cp.cp_department, i.i_brand, sm.sm_type, ib.ib_lower_bound, ib.ib_upper_bound, brand_max.max_price_for_brand)
    )
ORDER BY sum_sales DESC
LIMIT 100

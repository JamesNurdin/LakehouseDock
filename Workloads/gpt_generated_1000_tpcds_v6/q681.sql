WITH
    sales_detail_agg AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_sold_date_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_bill_addr_sk,
            cc.cc_name,
            cp.cp_department,
            p.p_promo_name,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_quantity) AS total_quantity,
            AVG(cs.cs_sales_price) AS avg_unit_price,
            COUNT(*) AS sales_transactions
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE cs.cs_sold_date_sk IN (
                SELECT d_date_sk
                FROM date_dim
                WHERE d_year = 2001
                  AND d_month_seq BETWEEN 1 AND 12
            )
          AND cs.cs_quantity > 0
          AND p.p_discount_active = 'Y'
          AND cc.cc_state = 'CA'
          AND cp.cp_type = 'catalog'
        GROUP BY
            cs.cs_item_sk,
            cs.cs_sold_date_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_bill_addr_sk,
            cc.cc_name,
            cp.cp_department,
            p.p_promo_name
    ),
    store_ret_agg AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_returned_date_sk,
            sr.sr_reason_sk,
            SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amt,
            COUNT(*) AS store_return_cnt
        FROM store_returns sr
        WHERE sr.sr_returned_date_sk IN (
                SELECT d_date_sk
                FROM date_dim
                WHERE d_year = 2001
            )
          AND sr.sr_return_quantity > 0
        GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk, sr.sr_reason_sk
    ),
    web_ret_agg AS (
        SELECT
            wr.wr_item_sk,
            wr.wr_returned_date_sk,
            wr.wr_reason_sk,
            SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amt,
            COUNT(*) AS web_return_cnt
        FROM web_returns wr
        WHERE wr.wr_returned_date_sk IN (
                SELECT d_date_sk
                FROM date_dim
                WHERE d_year = 2001
            )
          AND wr.wr_return_quantity > 0
        GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk, wr.wr_reason_sk
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_date,
    SA.cc_name,
    SA.cp_department,
    SA.p_promo_name,
    C.c_email_address,
    HD.hd_vehicle_count,
    CA.ca_city,
    SA.total_sales,
    SA.total_quantity,
    SA.avg_unit_price,
    SA.sales_transactions,
    COALESCE(SR.total_store_return_amt, 0) AS total_store_return_amt,
    COALESCE(SR.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(WR.total_web_return_amt, 0) AS total_web_return_amt,
    COALESCE(WR.web_return_cnt, 0) AS web_return_cnt,
    COALESCE(R1.r_reason_desc, R2.r_reason_desc) AS return_reason_desc
FROM sales_detail_agg SA
JOIN item i ON SA.cs_item_sk = i.i_item_sk
JOIN date_dim d ON SA.cs_sold_date_sk = d.d_date_sk
JOIN customer C ON SA.cs_bill_customer_sk = C.c_customer_sk
JOIN household_demographics HD ON SA.cs_bill_hdemo_sk = HD.hd_demo_sk
JOIN customer_address CA ON SA.cs_bill_addr_sk = CA.ca_address_sk
LEFT JOIN store_ret_agg SR ON SA.cs_item_sk = SR.sr_item_sk
    AND SA.cs_sold_date_sk = SR.sr_returned_date_sk
LEFT JOIN reason R1 ON SR.sr_reason_sk = R1.r_reason_sk
LEFT JOIN web_ret_agg WR ON SA.cs_item_sk = WR.wr_item_sk
    AND SA.cs_sold_date_sk = WR.wr_returned_date_sk
LEFT JOIN reason R2 ON WR.wr_reason_sk = R2.r_reason_sk
WHERE i.i_category = 'Sports'
  AND d.d_month_seq BETWEEN 1 AND 12
  AND d.d_year = 2001
ORDER BY SA.total_sales DESC
LIMIT 100

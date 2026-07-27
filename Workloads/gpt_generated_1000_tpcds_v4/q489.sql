WITH
    store_ret AS (
        SELECT
            sr.sr_store_sk,
            s.s_store_name,
            SUM(sr.sr_return_amt) AS total_return_amt,
            COUNT(*) AS return_cnt
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
        JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
        WHERE d_sr.d_year = 2001
          AND r_sr.r_reason_desc = 'Customer Not Satisfied'
          AND s.s_closed_date_sk IS NULL
        GROUP BY sr.sr_store_sk, s.s_store_name
    )
SELECT
    sr.s_store_name,
    sr.total_return_amt,
    sr.return_cnt,
    (
        SELECT SUM(cs.cs_ext_sales_price)
        FROM catalog_sales cs
        JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        WHERE d_cs.d_year = 2001
          AND p_cs.p_discount_active = 'Y'
          AND EXISTS (
                SELECT 1 FROM income_band ib
                WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
                  AND ib.ib_upper_bound >= 80000
          )
    ) AS total_catalog_sales,
    (
        SELECT SUM(ws.ws_ext_sales_price)
        FROM web_sales ws
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
        JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        WHERE d_ws.d_year = 2001
          AND p_ws.p_discount_active = 'Y'
    ) AS total_web_sales,
    (
        SELECT COUNT(DISTINCT cp.cp_catalog_page_sk)
        FROM catalog_page cp
        JOIN date_dim d_cp ON cp.cp_start_date_sk = d_cp.d_date_sk
        WHERE d_cp.d_year = 2001
          AND cp.cp_department = 'Electronics'
    ) AS catalog_pages_electronics,
    (
        SELECT COUNT(DISTINCT cs.cs_bill_customer_sk)
        FROM catalog_sales cs
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        WHERE ca.ca_county = 'Madison County'
          AND cd.cd_gender = 'M'
          AND cs.cs_sold_date_sk IN (
                SELECT d_date_sk FROM date_dim WHERE d_year = 2001
          )
    ) AS male_customers_madison,
    (
        SELECT SUM(wr.wr_return_amt)
        FROM web_returns wr
        JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        WHERE r_wr.r_reason_desc = 'Damaged'
    ) AS total_web_return_damaged,
    RANK() OVER (ORDER BY sr.total_return_amt DESC) AS store_return_rank
FROM store_ret sr
ORDER BY store_return_rank
LIMIT 100

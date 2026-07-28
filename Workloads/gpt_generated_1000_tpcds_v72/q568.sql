WITH joined AS (
    SELECT
        cc.cc_call_center_id,
        cp.cp_catalog_number,
        i.i_item_sk,
        i.i_category,
        i.i_manager_id,
        p.p_promo_id,
        p.p_cost,
        p.p_discount_active,
        w.w_warehouse_id,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq,
        c_bill.c_customer_id AS bill_customer_id,
        hd_bill.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_store_id,
        s.s_floor_space,
        r_sr.r_reason_desc AS store_return_reason,
        sr.sr_return_amt,
        cs.cs_net_paid,
        cs.cs_order_number,
        wr.wr_return_amt,
        r_wr.r_reason_desc AS web_return_reason,
        wp.wp_url
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
)
SELECT
    i_category,
    s_store_id,
    sold_year,
    cp_catalog_number,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_paid) AS total_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(wr_return_amt) AS total_web_returns,
    AVG(p_cost) AS avg_promo_cost,
    MIN(s_floor_space) AS min_floor_space,
    MAX(s_floor_space) AS max_floor_space,
    RANK() OVER (PARTITION BY i_category ORDER BY SUM(cs_net_paid) DESC) AS category_sales_rank
FROM joined
WHERE
    cp_catalog_number IN (10, 14)
    AND i_manager_id = 44
    AND s_floor_space > 7000000
    AND sold_year = 2001
    AND p_discount_active = 'Y'
    AND store_return_reason LIKE '%defect%'
GROUP BY
    i_category,
    s_store_id,
    sold_year,
    cp_catalog_number
ORDER BY
    total_sales DESC,
    category_sales_rank
LIMIT 100

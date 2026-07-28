WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        d_sales.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        ss.ss_hdemo_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, d_sales.d_year, ss.ss_hdemo_sk, ss.ss_sold_date_sk, ss.ss_sold_time_sk
),
catalog_ret_agg AS (
    SELECT
        cr.cr_item_sk,
        d_ret.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        MIN(cc.cc_name) AS any_call_center_name,
        MIN(cp.cp_type) AS any_catalog_page_type,
        MIN(w.w_warehouse_name) AS any_warehouse_name,
        MIN(ca.ca_city) AS any_customer_city
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY cr.cr_item_sk, d_ret.d_year
),
web_ret_agg AS (
    SELECT
        wr.wr_item_sk,
        d_ret2.d_year,
        SUM(wr.wr_return_amt) AS total_return_amount,
        MIN(wp.wp_url) AS any_web_page_url
    FROM web_returns wr
    JOIN date_dim d_ret2 ON wr.wr_returned_date_sk = d_ret2.d_date_sk
    JOIN time_dim t_ret2 ON wr.wr_returned_time_sk = t_ret2.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY wr.wr_item_sk, d_ret2.d_year
)
SELECT
    s.s_store_name,
    i.i_item_id,
    sa.d_year,
    sa.total_sales,
    COALESCE(cr.total_return_amount, 0) AS catalog_return_amount,
    COALESCE(wr.total_return_amount, 0) AS web_return_amount,
    (sa.total_sales - COALESCE(cr.total_return_amount, 0) - COALESCE(wr.total_return_amount, 0)) AS net_sales_after_returns,
    CASE
        WHEN ib.ib_upper_bound >= 150000 THEN 'High Income'
        ELSE 'Mid/Low Income'
    END AS income_band_category,
    CASE
        WHEN sa.total_sales > (SELECT AVG(ss_ext_sales_price) FROM store_sales) THEN 'Above Avg Sale'
        ELSE 'Below Avg Sale'
    END AS sales_category,
    sa.distinct_customers,
    cr.any_call_center_name,
    cr.any_catalog_page_type,
    cr.any_warehouse_name,
    cr.any_customer_city,
    wr.any_web_page_url
FROM sales_agg sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
JOIN household_demographics hd ON sa.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_ret_agg cr ON cr.cr_item_sk = i.i_item_sk AND cr.d_year = sa.d_year
LEFT JOIN web_ret_agg wr ON wr.wr_item_sk = i.i_item_sk AND wr.d_year = sa.d_year
WHERE s.s_state = 'CA'
ORDER BY net_sales_after_returns DESC
LIMIT 100

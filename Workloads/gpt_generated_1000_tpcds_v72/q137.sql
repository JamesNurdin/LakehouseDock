WITH per_item_month AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_product_name AS product_name,
        d_sold.d_year AS year,
        d_sold.d_month_seq AS month_seq,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(p.p_cost) AS total_promo_cost
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
    JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = c_bill.c_customer_sk
    JOIN date_dim d_store_ret ON sr.sr_returned_date_sk = d_store_ret.d_date_sk
    JOIN time_dim t_store_ret ON sr.sr_return_time_sk = t_store_ret.t_time_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d_sold.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND p.p_response_target > 5
      AND sm.sm_type = 'AIR'
      AND ca_bill.ca_gmt_offset = -5.00
      AND ws.ws_ext_list_price > 1000
      AND cp.cp_type = 'SPECIAL'
    GROUP BY
        i.i_item_sk,
        i.i_product_name,
        d_sold.d_year,
        d_sold.d_month_seq
)
SELECT
    item_sk,
    product_name,
    year,
    month_seq,
    total_catalog_sales,
    total_catalog_returns,
    total_store_returns,
    total_web_sales,
    total_promo_cost,
    (total_catalog_sales + total_web_sales - total_catalog_returns - total_store_returns) / NULLIF(total_promo_cost, 0) AS sales_per_promo_cost
FROM per_item_month
WHERE total_promo_cost > 0
ORDER BY year DESC, month_seq, total_catalog_sales DESC
LIMIT 100

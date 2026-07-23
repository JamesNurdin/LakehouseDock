WITH ws_agg AS (
    SELECT
        ws_order_number,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_bill_customer_sk,
        ws_bill_hdemo_sk,
        ws_bill_addr_sk,
        ws_ship_customer_sk,
        ws_ship_hdemo_sk,
        ws_ship_addr_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        ws_promo_sk,
        ws_web_page_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2451179
    GROUP BY ws_order_number,
             ws_sold_date_sk,
             ws_sold_time_sk,
             ws_bill_customer_sk,
             ws_bill_hdemo_sk,
             ws_bill_addr_sk,
             ws_ship_customer_sk,
             ws_ship_hdemo_sk,
             ws_ship_addr_sk,
             ws_ship_mode_sk,
             ws_warehouse_sk,
             ws_promo_sk,
             ws_web_page_sk
)
SELECT
    d_sold.d_year AS sold_year,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_country,
    hd.hd_income_band_sk,
    p.p_promo_name,
    sm.sm_type,
    w.w_warehouse_name,
    cp.cp_department,
    cp.cp_catalog_number,
    cat_sales.cs_quantity,
    cat_sales.cs_net_profit,
    ws_agg.total_net_profit,
    ws_agg.total_quantity,
    ws_agg.total_sales,
    RANK() OVER (PARTITION BY d_sold.d_year ORDER BY ws_agg.total_net_profit DESC) AS profit_rank,
    DENSE_RANK() OVER (ORDER BY cp.cp_department) AS dept_dense_rank,
    ROW_NUMBER() OVER (ORDER BY ws_agg.total_sales DESC) AS row_num
FROM ws_agg
JOIN date_dim d_sold
    ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON ws_agg.ws_sold_time_sk = t_sold.t_time_sk
JOIN customer c
    ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ws_agg.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON ws_agg.ws_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm
    ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
    ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN catalog_sales cat_sales
    ON cat_sales.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp
    ON cat_sales.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cat_sold
    ON cat_sales.cs_sold_date_sk = d_cat_sold.d_date_sk
JOIN time_dim t_cat
    ON cat_sales.cs_sold_time_sk = t_cat.t_time_sk
JOIN ship_mode sm2
    ON cat_sales.cs_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN warehouse w2
    ON cat_sales.cs_warehouse_sk = w2.w_warehouse_sk
JOIN promotion p2
    ON cat_sales.cs_promo_sk = p2.p_promo_sk
JOIN household_demographics hd2
    ON cat_sales.cs_bill_hdemo_sk = hd2.hd_demo_sk
JOIN customer_address ca2
    ON cat_sales.cs_bill_addr_sk = ca2.ca_address_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws_agg.ws_order_number
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND ca.ca_country = 'United States'
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
ORDER BY d_sold.d_year DESC, ws_agg.total_net_profit DESC
LIMIT 100

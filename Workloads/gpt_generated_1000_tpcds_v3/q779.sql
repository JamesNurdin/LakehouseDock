WITH sales_data AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        d_ss.d_year AS d_year,
        d_ss.d_month_seq AS d_month_seq,
        ss.ss_net_paid AS store_net_paid,
        ss.ss_ext_discount_amt AS store_discount,
        cs.cs_net_paid AS catalog_net_paid,
        cs.cs_ext_discount_amt AS catalog_discount,
        ws.ws_net_paid AS web_net_paid,
        ws.ws_ext_discount_amt AS web_discount,
        sr.sr_net_loss AS store_return_loss,
        wr.wr_net_loss AS web_return_loss,
        c_ss.c_customer_sk AS store_customer_sk,
        ca_ss.ca_city AS store_city,
        sm_cs.sm_type AS cs_ship_type,
        sm_ws.sm_type AS ws_ship_type,
        w_cs.w_warehouse_name AS cs_warehouse_name,
        w_ws.w_warehouse_name AS ws_warehouse_name,
        r_sr.r_reason_desc AS store_return_reason,
        r_wr.r_reason_desc AS web_return_reason,
        wp.wp_url AS web_page_url,
        we.web_name AS web_site_name
    FROM item i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN customer c_cs_bill ON cs.cs_bill_customer_sk = c_cs_bill.c_customer_sk
    JOIN customer_address ca_cs_bill ON cs.cs_bill_addr_sk = ca_cs_bill.ca_address_sk
    JOIN customer c_cs_ship ON cs.cs_ship_customer_sk = c_cs_ship.c_customer_sk
    JOIN customer_address ca_cs_ship ON cs.cs_ship_addr_sk = ca_cs_ship.ca_address_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer c_ws_ship ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN store s_sr ON sr.sr_store_sk = s_sr.s_store_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    JOIN customer c_wr_refunded ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
    JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    JOIN customer c_wr_returning ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
    JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    WHERE d_ss.d_year = 2001
      AND c_ss.c_birth_country = 'UNITED ARAB EMIRATES'
)
SELECT
    i_item_id,
    i_product_name,
    d_year,
    d_month_seq,
    SUM(store_net_paid) AS total_store_sales,
    SUM(catalog_net_paid) AS total_catalog_sales,
    SUM(web_net_paid) AS total_web_sales,
    SUM(store_discount) AS total_store_discount,
    SUM(catalog_discount) AS total_catalog_discount,
    SUM(web_discount) AS total_web_discount,
    SUM(store_return_loss) AS total_store_return_loss,
    SUM(web_return_loss) AS total_web_return_loss,
    COUNT(DISTINCT store_customer_sk) AS distinct_store_customers,
    MIN(store_city) AS sample_store_city,
    MIN(cs_ship_type) AS sample_cs_ship_type,
    MIN(ws_ship_type) AS sample_ws_ship_type,
    MIN(cs_warehouse_name) AS sample_cs_warehouse,
    MIN(ws_warehouse_name) AS sample_ws_warehouse,
    MIN(store_return_reason) AS sample_store_return_reason,
    MIN(web_return_reason) AS sample_web_return_reason,
    MIN(web_page_url) AS sample_web_page_url,
    MIN(web_site_name) AS sample_web_site_name
FROM sales_data
GROUP BY i_item_id, i_product_name, d_year, d_month_seq
HAVING SUM(store_net_paid) > (
    SELECT AVG(cs.cs_net_paid)
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
)
ORDER BY total_store_sales DESC
LIMIT 100

WITH base AS (
    SELECT DISTINCT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ws.ws_net_paid,
        ws.ws_net_profit,
        sr.sr_return_amt,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        d_sales.d_year,
        d_sales.d_month_seq,
        t_sales.t_shift,
        w_warehouse.w_warehouse_name,
        cc.cc_name,
        cp.cp_catalog_page_number,
        wp.wp_url,
        web.web_name,
        ca_cs.ca_city,
        ca_ws.ca_city AS ws_city,
        ca_sr.ca_city AS sr_city
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN tpcds.time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.warehouse w_warehouse ON cs.cs_warehouse_sk = w_warehouse.w_warehouse_sk
    JOIN tpcds.customer_address ca_cs ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
    
    -- join web_sales (shares many dimension keys)
    JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN tpcds.date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN tpcds.time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN tpcds.customer c_ws ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    JOIN tpcds.customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    JOIN tpcds.household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN tpcds.income_band ib_ws ON hd_ws.hd_income_band_sk = ib_ws.ib_income_band_sk
    JOIN tpcds.customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN tpcds.date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN tpcds.web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN tpcds.date_dim d_web_open ON web.web_open_date_sk = d_web_open.d_date_sk
    JOIN tpcds.date_dim d_web_close ON web.web_close_date_sk = d_web_close.d_date_sk
    
    -- join store_returns
    JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN tpcds.time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN tpcds.customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN tpcds.customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN tpcds.household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN tpcds.income_band ib_sr ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
    JOIN tpcds.customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    
    -- call_center date joins (optional, just to include the table)
    JOIN tpcds.date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN tpcds.date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    
    WHERE d_sales.d_year = 2001
      AND i.i_current_price > 100
      AND cd.cd_gender = 'M'
),
aggregated AS (
    SELECT
        c_customer_id AS customer_id,
        c_first_name AS first_name,
        c_last_name AS last_name,
        cd_gender AS gender,
        SUM(cs_net_paid) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(sr_return_amt) AS total_returns,
        SUM(cs_net_paid) - SUM(sr_return_amt) AS net_total,
        ROW_NUMBER() OVER (ORDER BY (SUM(cs_net_paid) - SUM(sr_return_amt)) DESC) AS rank_by_net_total
    FROM base
    GROUP BY c_customer_id, c_first_name, c_last_name, cd_gender
)
SELECT
    customer_id,
    first_name,
    last_name,
    gender,
    total_sales,
    total_profit,
    total_returns,
    net_total,
    rank_by_net_total
FROM aggregated
WHERE net_total > 0
ORDER BY net_total DESC
LIMIT 100

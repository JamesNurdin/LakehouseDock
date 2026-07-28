WITH agg AS (
    SELECT
        i.i_category,
        d_sold.d_year,
        cp.cp_department,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(wr.wr_return_amt) AS total_web_returns,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM
        catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
        JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
        JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
        -- additional date joins for catalog_page and promotion
        JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
        JOIN date_dim d_cp_end   ON cp.cp_end_date_sk   = d_cp_end.d_date_sk
        JOIN date_dim d_p_start  ON p_cs.p_start_date_sk = d_p_start.d_date_sk
        JOIN date_dim d_p_end    ON p_cs.p_end_date_sk   = d_p_end.d_date_sk
        -- web sales and its related dimensions
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        -- promotion dates for web sales
        JOIN date_dim d_p_ws_start ON p_ws.p_start_date_sk = d_p_ws_start.d_date_sk
        JOIN date_dim d_p_ws_end   ON p_ws.p_end_date_sk   = d_p_ws_end.d_date_sk
        -- web returns linked to web sales
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
        JOIN customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
        JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
        JOIN customer_demographics cd_wr_return ON wr.wr_returning_cdemo_sk = cd_wr_return.cd_demo_sk
        JOIN customer_address ca_wr_return ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
        JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
        -- store returns linked through the item dimension
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
        JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
        JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
        -- web page date attributes
        JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
        JOIN date_dim d_wp_access   ON wp.wp_access_date_sk   = d_wp_access.d_date_sk
    GROUP BY GROUPING SETS (
        (i.i_category, d_sold.d_year, cp.cp_department),
        (i.i_category, cp.cp_department),
        (i.i_category),
        ()
    )
)
SELECT
    i_category,
    d_year,
    cp_department,
    total_catalog_sales,
    total_web_sales,
    total_store_returns,
    total_web_returns,
    CASE WHEN total_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_catalog_sales DESC) AS sales_rank
FROM agg
ORDER BY i_category, d_year, cp_department
LIMIT 100

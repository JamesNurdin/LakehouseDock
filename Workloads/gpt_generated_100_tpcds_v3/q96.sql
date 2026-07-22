WITH sales_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(sr.sr_return_amt) AS store_return_total,
        SUM(wr.wr_return_amt) AS web_return_total,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
        cp.cp_department,
        ws.web_site_id,
        wp.wp_url,
        (SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) -
         SUM(sr.sr_return_amt) - SUM(wr.wr_return_amt)) AS net_sales
    FROM
        catalog_sales cs
        JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
                               AND ss.ss_item_sk = i.i_item_sk
        JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
        JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
        JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
        JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
        JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
        JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
        JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
        JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
        CROSS JOIN web_site ws
        JOIN date_dim d_ws ON ws.web_open_date_sk = d_ws.d_date_sk
    WHERE
        d_cs.d_year = 2001
        AND cd.cd_gender = 'F'
        AND hd.hd_buy_potential = '5000-10000'
        AND i.i_brand = 'Brand#12'
        AND r_sr.r_reason_id = 'AAAAAAAALAAAAAAA'
        AND t_cs.t_shift = 'first'
        AND cs.cs_quantity > 1
        AND cp.cp_department = 'Books'
        AND ws.web_site_id = 'web_site_1'
        AND d_ws.d_year = 2001
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id,
        i.i_product_name,
        cp.cp_department,
        ws.web_site_id,
        wp.wp_url
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    i_item_id,
    i_product_name,
    catalog_sales_total,
    store_sales_total,
    store_return_total,
    web_return_total,
    total_inventory_on_hand,
    cp_department,
    web_site_id,
    wp_url,
    net_sales,
    DENSE_RANK() OVER (ORDER BY net_sales DESC) AS sales_rank
FROM sales_data
ORDER BY sales_rank, net_sales DESC
LIMIT 100

WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        s.s_store_name,
        sm.sm_type,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        ss.ss_net_paid,
        wr.wr_return_amt
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                             AND ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                             AND wr.wr_item_sk = i.i_item_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        d.d_year = 2001
        AND i.i_category = 'Electronics'
        AND ca.ca_state = 'CA'
        AND sm.sm_type = 'AIR'
        AND wp.wp_autogen_flag = 'N'
)
SELECT
    d_year,
    i_category,
    s_store_name,
    sm_type,
    COUNT(DISTINCT cs_order_number) AS num_catalog_orders,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(wr_return_amt) AS total_returns,
    AVG(cs_ext_discount_amt) AS avg_catalog_discount,
    MIN(cs_net_paid) AS min_catalog_sale,
    MAX(cs_net_paid) AS max_catalog_sale
FROM base
GROUP BY
    d_year,
    i_category,
    s_store_name,
    sm_type
ORDER BY total_catalog_sales DESC
LIMIT 100

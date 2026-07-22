WITH distinct_items AS (
    SELECT DISTINCT cs.cs_item_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
)
SELECT
    i_cs.i_item_id,
    i_cs.i_product_name,
    i_cs.i_brand,
    i_cs.i_class,
    i_cs.i_category,
    cc.cc_name AS call_center_name,
    cp.cp_catalog_number,
    wp.wp_type AS web_page_type,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cs.cs_quantity) AS total_sales_quantity,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(sr.sr_return_quantity) AS total_store_return_quantity,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(wr.wr_return_quantity) AS total_web_return_quantity,
    COUNT(DISTINCT c_bill.c_customer_id) AS distinct_buyers,
    COUNT(DISTINCT c_wr_refunded.c_customer_id) AS distinct_refunded_customers,
    COUNT(DISTINCT c_wr_returning.c_customer_id) AS distinct_returning_customers
FROM
    distinct_items di
    JOIN catalog_sales cs
        ON cs.cs_item_sk = di.cs_item_sk
    JOIN item i_cs
        ON cs.cs_item_sk = i_cs.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i_cs.i_item_sk
    LEFT JOIN customer c_sr
        ON sr.sr_customer_sk = c_sr.c_customer_sk
    LEFT JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    LEFT JOIN customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    LEFT JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i_cs.i_item_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN customer c_wr_refunded
        ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
    LEFT JOIN customer_address ca_wr_refunded
        ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    LEFT JOIN customer_demographics cd_wr_refunded
        ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    LEFT JOIN household_demographics hd_wr_refunded
        ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    LEFT JOIN customer c_wr_returning
        ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
    LEFT JOIN customer_address ca_wr_returning
        ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    LEFT JOIN customer_demographics cd_wr_returning
        ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    LEFT JOIN household_demographics hd_wr_returning
        ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
WHERE
    cc.cc_rec_start_date >= DATE '2000-01-01'
    AND cc.cc_rec_start_date < DATE '2002-01-01'
    AND wp.wp_max_ad_count >= 2
    AND i_cs.i_class_id IN (11, 16)
    AND i_cs.i_formulation LIKE '%goldenrod%'
GROUP BY
    i_cs.i_item_id,
    i_cs.i_product_name,
    i_cs.i_brand,
    i_cs.i_class,
    i_cs.i_category,
    cc.cc_name,
    cp.cp_catalog_number,
    wp.wp_type
ORDER BY
    total_sales_profit DESC
LIMIT 100

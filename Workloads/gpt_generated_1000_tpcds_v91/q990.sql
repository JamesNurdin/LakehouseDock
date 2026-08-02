WITH orders_without_returns AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
),
joined_data AS (
    SELECT
        d_sold.d_year AS d_year,
        i.i_brand AS i_brand,
        w.w_warehouse_name AS w_warehouse_name,
        cp.cp_department AS cp_department,
        wp.wp_type AS wp_type,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        sr.sr_return_amt_inc_tax,
        CASE WHEN cs.cs_ext_sales_price > 1000 THEN cs.cs_ext_sales_price ELSE 0 END AS high_value_sales
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d_sold.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM orders_without_returns)
      AND d_sold.d_year = 2001
      AND i.i_size IN ('large', 'extra large')
      AND ca_bill.ca_state = 'CA'
      AND hd_bill.hd_income_band_sk = 5
      AND wp.wp_type = 'Content'
      AND cs.cs_ext_discount_amt > 10.00
      AND w.w_warehouse_sq_ft > 12000
)
SELECT
    d_year,
    i_brand,
    w_warehouse_name,
    cp_department,
    wp_type,
    COUNT(DISTINCT cs_order_number) AS order_count,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(sr_return_amt_inc_tax) AS total_returns,
    SUM(cs_net_profit) AS total_profit,
    AVG(cs_ext_discount_amt) AS avg_discount,
    SUM(high_value_sales) AS total_high_value_sales,
    MIN(cs_ext_sales_price) AS min_sales_price,
    MAX(cs_ext_sales_price) AS max_sales_price
FROM joined_data
GROUP BY d_year, i_brand, w_warehouse_name, cp_department, wp_type
ORDER BY total_sales DESC
LIMIT 100

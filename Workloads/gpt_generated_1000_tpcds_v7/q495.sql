WITH sales_agg AS (
    SELECT
        cp.cp_department               AS department,
        i.i_brand                      AS brand,
        SUM(cs.cs_ext_sales_price)    AS total_sales,
        SUM(cr.cr_return_amount)      AS total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        AVG(cs.cs_ext_sales_price)    AS avg_sales_price
    FROM catalog_sales cs
    JOIN catalog_page cp        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i                 ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w            ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm           ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c             ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca    ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr    ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r               ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss         ON ss.ss_item_sk = i.i_item_sk
    WHERE cp.cp_department = 'Kids'
      AND i.i_brand = 'Brand#12'
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND c.c_preferred_cust_flag = 'Y'
      AND cd.cd_purchase_estimate > 5000
      AND r.r_reason_desc LIKE '%price%'
    GROUP BY cp.cp_department, i.i_brand
)
SELECT
    department,
    brand,
    total_sales,
    total_returns,
    num_orders,
    total_sales - total_returns                         AS net_sales,
    (total_sales - total_returns) / NULLIF(total_sales, 0) AS net_sales_ratio,
    (SELECT AVG(cs_ext_sales_price) FROM catalog_sales) AS overall_avg_sales_price,
    (SELECT COUNT(*)
       FROM catalog_returns cr2
       JOIN catalog_sales cs2 ON cr2.cr_order_number = cs2.cs_order_number
       JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
       WHERE cp2.cp_department = sales_agg.department
         AND cr2.cr_return_amount > 1000)               AS high_return_count
FROM sales_agg
WHERE (total_sales - total_returns) > 10000
ORDER BY net_sales DESC
LIMIT 20

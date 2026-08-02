WITH filtered_catalog AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_net_paid,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
    WHERE cs.cs_warehouse_sk IN (
            SELECT w_warehouse_sk
            FROM warehouse
            WHERE w_city = 'Spring'
        )
      AND cs.cs_bill_customer_sk IN (
            SELECT c_customer_sk
            FROM customer
            WHERE c_preferred_cust_flag = 'Y'
            INTERSECT
            SELECT cs_bill_customer_sk
            FROM catalog_sales
            WHERE cs_ext_sales_price > 1000
        )
      AND NOT EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = cs.cs_order_number
        )
      AND cs.cs_sold_date_sk = (
            SELECT max(d_date_sk)
            FROM date_dim
        )
)
SELECT
    fc.cs_order_number,
    fc.cs_net_paid,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    cc.cc_name,
    w.w_warehouse_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    t.t_hour,
    cd.cd_gender,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN hd.hd_vehicle_count > 1 THEN 'Multi-Vehicle'
        ELSE 'Single-or-None'
    END AS vehicle_category,
    ROW_NUMBER() OVER (
        PARTITION BY fc.cs_call_center_sk
        ORDER BY fc.cs_net_paid DESC
    ) AS rn_by_cc,
    SUM(fc.cs_net_paid) OVER (
        PARTITION BY fc.cs_call_center_sk
        ORDER BY fc.cs_sold_date_sk
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS moving_sum_net_paid,
    ss.ss_quantity,
    ss.ss_net_paid AS ss_net_paid,
    wp.wp_url,
    r.r_reason_desc,
    wr.wr_return_amt
FROM filtered_catalog fc
JOIN call_center cc ON fc.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON fc.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON fc.cs_item_sk = i.i_item_sk
JOIN date_dim d_sold ON fc.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t ON fc.cs_sold_time_sk = t.t_time_sk
JOIN customer cust ON fc.cs_bill_customer_sk = cust.c_customer_sk
JOIN customer_demographics cd ON fc.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON fc.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON fc.cs_bill_addr_sk = ca.ca_address_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = fc.cs_sold_date_sk
   AND ss.ss_sold_time_sk = t.t_time_sk
   AND ss.ss_item_sk = i.i_item_sk
   AND ss.ss_customer_sk = cust.c_customer_sk
   AND ss.ss_cdemo_sk = cd.cd_demo_sk
   AND ss.ss_hdemo_sk = hd.hd_demo_sk
   AND ss.ss_addr_sk = ca.ca_address_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_refunded_customer_sk = cust.c_customer_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE EXISTS (
    SELECT 1
    FROM web_page wp2
    WHERE wp2.wp_customer_sk = cust.c_customer_sk
)
LIMIT 100

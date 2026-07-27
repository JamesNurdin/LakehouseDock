WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ship_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_wholesale_cost,
        cs.cs_list_price,
        cs.cs_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_ext_sales_price,
        cs.cs_ext_wholesale_cost,
        cs.cs_ext_list_price,
        cs.cs_ext_tax,
        cs.cs_coupon_amt,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_paid_inc_ship,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_type,
        cp.cp_catalog_number,
        sm.sm_code,
        sm.sm_carrier,
        p.p_channel_tv,
        p.p_discount_active
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cp.cp_department = 'Sports'
      AND cp.cp_type = 'Standard'
      AND cp.cp_catalog_number IN (4, 12)
      AND sm.sm_code = 'AIR'
      AND sm.sm_carrier = 'FedEx'
      AND p.p_channel_tv = 'Y'
      AND p.p_discount_active = 'Y'
)
SELECT
    cp_department,
    sm_code,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs_order_number) AS distinct_orders
FROM filtered_sales
GROUP BY ROLLUP(cp_department, sm_code)
ORDER BY cp_department ASC NULLS LAST, sm_code ASC NULLS LAST
LIMIT 100

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
        cp.cp_catalog_number,
        sm.sm_ship_mode_id,
        sm.sm_code
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sales_price > 20
      AND cp.cp_catalog_number IN (3, 4)
      AND sm.sm_code = 'AIR'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
            AND cs2.cs_quantity > 100
      )
),
agg AS (
    SELECT
        cp_department,
        cp_catalog_number,
        sm_ship_mode_id,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_paid) AS avg_net_paid,
        COUNT(*) AS sales_cnt,
        MIN(cs_sales_price) AS min_price,
        MAX(cs_sales_price) AS max_price,
        ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY SUM(cs_ext_sales_price) DESC) AS dept_sales_rank
    FROM filtered_sales
    GROUP BY cp_department, cp_catalog_number, sm_ship_mode_id
),
customer_set1 AS (
    SELECT DISTINCT cs_bill_customer_sk
    FROM filtered_sales
),
customer_set2 AS (
    SELECT DISTINCT cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code <> 'AIR'
),
customer_diff AS (
    SELECT cs_bill_customer_sk FROM customer_set1
    EXCEPT
    SELECT cs_bill_customer_sk FROM customer_set2
)
SELECT DISTINCT
    a.cp_department,
    a.cp_catalog_number,
    a.sm_ship_mode_id,
    a.total_sales,
    a.avg_net_paid,
    a.sales_cnt,
    a.min_price,
    a.max_price,
    a.dept_sales_rank,
    cd.cs_bill_customer_sk
FROM agg a
LEFT JOIN customer_diff cd ON true
ORDER BY a.total_sales DESC
LIMIT 100

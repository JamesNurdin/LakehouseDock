WITH sales_agg AS (
    SELECT
        cc.cc_name,
        w.w_warehouse_name,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        MIN(cs.cs_ext_sales_price) AS min_sales,
        MAX(cs.cs_ext_sales_price) AS max_sales
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        cc.cc_company = 3
        AND cc.cc_mkt_id IN (2, 4, 5)
        AND cs.cs_ship_date_sk BETWEEN 2450842 AND 2450881
        AND cs.cs_ext_wholesale_cost > 1000
        AND cd.cd_credit_rating = 'Good'
        AND cd.cd_purchase_estimate >= 4000
        AND i.i_color = 'Red'
        AND NOT EXISTS (
            SELECT 1 FROM inventory inv2
            WHERE inv2.inv_item_sk = cs.cs_item_sk
              AND inv2.inv_warehouse_sk = cs.cs_warehouse_sk
              AND inv2.inv_quantity_on_hand = 0
        )
    GROUP BY
        cc.cc_name,
        w.w_warehouse_name,
        i.i_category
)
SELECT
    sa.cc_name,
    sa.w_warehouse_name,
    sa.i_category,
    sa.total_sales,
    sa.avg_discount,
    sa.distinct_customers,
    sa.distinct_items,
    sa.min_sales,
    sa.max_sales,
    (SELECT AVG(cs3.cs_ext_discount_amt) FROM catalog_sales cs3 WHERE cs3.cs_ext_wholesale_cost > 500) AS overall_avg_discount,
    ROW_NUMBER() OVER (ORDER BY sa.total_sales DESC) AS rn,
    SUM(sa.total_sales) OVER (PARTITION BY sa.cc_name) AS cum_sales_by_cc
FROM sales_agg sa
ORDER BY sa.total_sales DESC
LIMIT 100

WITH sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        i.i_category,
        SUM(cs.cs_net_paid_inc_ship) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        MIN(inv.inv_quantity_on_hand) AS min_on_hand,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_department = 'Electronics'
      AND i.i_brand = 'Brand#12'
      AND p.p_channel_email = 'Y'
      AND inv.inv_quantity_on_hand >= 500
      AND cs.cs_sold_date_sk BETWEEN 2450900 AND 2451000
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, i.i_category
)
SELECT
    w_warehouse_name,
    i_category,
    total_sales,
    avg_discount,
    min_on_hand,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY i_category, sales_rank

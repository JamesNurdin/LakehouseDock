WITH joined_data AS (
    SELECT
        cc.cc_name,
        i.i_brand,
        ss.ss_ext_sales_price,
        cr.cr_return_amount,
        ss.ss_ticket_number,
        cp.cp_type,
        w.w_city,
        cc.cc_state,
        i.i_class_id,
        i.i_units,
        ss.ss_sold_date_sk,
        i.i_item_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_class_id IN (1, 4, 9)
      AND i.i_units = 'Each'
      AND cc.cc_state = 'CA'
      AND w.w_city = 'Seattle'
      AND cp.cp_type = 'A'
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_return_amount > 1000
            AND cr2.cr_item_sk = i.i_item_sk
      )
),
aggregated AS (
    SELECT
        cc_name,
        i_brand,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT ss_ticket_number) AS num_transactions,
        AVG(ss_ext_sales_price) AS avg_sales
    FROM joined_data
    GROUP BY GROUPING SETS (
        (cc_name, i_brand),
        (cc_name),
        (i_brand),
        ()
    )
    HAVING SUM(ss_ext_sales_price) > 10000
)
SELECT
    cc_name,
    i_brand,
    total_sales,
    total_return_amount,
    num_transactions,
    avg_sales,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_sales DESC) AS sales_rank,
    (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100

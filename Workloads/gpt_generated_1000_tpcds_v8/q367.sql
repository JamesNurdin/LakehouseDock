WITH intersect_items AS (
    SELECT cr_item_sk FROM tpcds.catalog_returns WHERE cr_return_amount > 200
    INTERSECT
    SELECT i_item_sk FROM tpcds.item WHERE i_current_price < 20
),
base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        d.d_date,
        d.d_year,
        t.t_hour,
        i.i_brand,
        i.i_category,
        cc.cc_name,
        cp.cp_department,
        cp.cp_type
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2002
      AND i.i_current_price > 50
      AND cc.cc_state = 'CA'
      AND NOT EXISTS (
          SELECT 1 FROM tpcds.catalog_returns cr2
          WHERE cr2.cr_order_number = cr.cr_order_number
            AND cr2.cr_return_amount > 100
      )
      AND cr.cr_item_sk NOT IN (SELECT cr_item_sk FROM intersect_items)
)
SELECT
    i_brand,
    d_year,
    cc_name,
    cp_department,
    COUNT(*) AS total_returns,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT i_category) AS distinct_categories,
    SUM(DISTINCT cr_return_tax) AS distinct_return_tax,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY SUM(cr_return_amount) DESC) AS brand_rn,
    RANK() OVER (ORDER BY SUM(cr_return_amount) DESC) AS global_rk
FROM base
GROUP BY GROUPING SETS (
    (i_brand, d_year, cc_name, cp_department),
    (i_brand, d_year, cc_name),
    (i_brand, d_year),
    ()
)
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
OFFSET 0 LIMIT 100

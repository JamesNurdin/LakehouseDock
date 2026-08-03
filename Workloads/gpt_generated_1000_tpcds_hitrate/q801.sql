WITH joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_order_number,
        i.i_item_id,
        i.i_product_name,
        cd.cd_gender,
        cp.cp_catalog_number,
        sm.sm_type,
        w.w_warehouse_name,
        r.r_reason_desc,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        ROW_NUMBER() OVER (ORDER BY cr.cr_return_amount DESC)               AS global_row_num,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cr.cr_return_amount DESC) AS warehouse_rank
    FROM catalog_returns cr
    RIGHT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 1
      AND i.i_current_price BETWEEN 10 AND 500
      AND cd.cd_gender = 'M'
      AND cp.cp_catalog_number IN (11, 13, 20)
      AND w.w_country = 'United States'
      AND sm.sm_type = 'AIR'
      AND cr.cr_reason_sk NOT IN (
          SELECT r2.r_reason_sk
          FROM reason r2
          WHERE r2.r_reason_desc LIKE '%defect%'
      )
)
SELECT *
FROM joined
WHERE warehouse_rank <= 5
ORDER BY global_row_num
LIMIT 100

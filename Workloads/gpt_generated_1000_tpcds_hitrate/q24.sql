WITH joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_catalog_page_sk,
        i.i_item_id,
        i.i_brand,
        i.i_color,
        cp.cp_catalog_page_id,
        cp.cp_type,
        rs.r_reason_desc,
        sm.sm_carrier,
        sm.sm_contract
    FROM catalog_returns cr
    RIGHT OUTER JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    RIGHT OUTER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    RIGHT OUTER JOIN reason rs
        ON cr.cr_reason_sk = rs.r_reason_sk
    RIGHT OUTER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        rs.r_reason_desc LIKE '%color%'
        AND cp.cp_type = 'monthly'
        AND sm.sm_carrier = 'FEDEX'
        AND i.i_brand = 'BrandX'
        AND i.i_color = 'Red'
        AND cp.cp_start_date_sk BETWEEN 2450845 AND 2451362
)
SELECT
    j.i_item_id,
    j.i_brand,
    j.i_color,
    j.cp_catalog_page_id,
    j.r_reason_desc,
    j.sm_carrier,
    j.sm_contract,
    j.cr_return_amount,
    j.cr_return_quantity,
    j.cr_net_loss,
    (
        SELECT COUNT(*)
        FROM catalog_page cp_sub
        WHERE cp_sub.cp_catalog_page_sk = j.cr_catalog_page_sk
    ) AS catalog_page_match_count,
    ROW_NUMBER() OVER (PARTITION BY j.r_reason_desc ORDER BY j.cr_return_amount DESC) AS reason_return_rank,
    SUM(j.cr_return_amount) OVER (
        PARTITION BY j.i_brand
        ORDER BY j.cr_return_amount
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_brand
FROM joined j
ORDER BY reason_return_rank, cumulative_return_by_brand DESC
LIMIT 100

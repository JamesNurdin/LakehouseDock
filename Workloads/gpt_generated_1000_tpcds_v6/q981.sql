WITH catalog_agg AS (
    SELECT
        cr_item_sk,
        cr_reason_sk,
        SUM(cr_return_amount) AS total_cat_return_amount,
        SUM(cr_return_quantity) AS total_cat_return_qty
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450000 AND 2453650
      AND cr_return_amount > 0
      AND cr_return_quantity > 0
    GROUP BY cr_item_sk, cr_reason_sk
)
SELECT
    i.i_item_id,
    i.i_category,
    i.i_class,
    r.r_reason_desc,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    wp.wp_type,
    ca.total_cat_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    CASE
        WHEN SUM(wr.wr_return_amt) > ca.total_cat_return_amount THEN 'WEB > CAT'
        ELSE 'CAT >= WEB'
    END AS comparison_flag
FROM catalog_agg ca
JOIN item i
    ON ca.cr_item_sk = i.i_item_sk
JOIN reason r
    ON ca.cr_reason_sk = r.r_reason_sk
-- Join a raw catalog_returns row to bring in the remaining dimensions
JOIN catalog_returns cr2
    ON cr2.cr_item_sk = i.i_item_sk
   AND cr2.cr_reason_sk = r.r_reason_sk
JOIN call_center cc
    ON cr2.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr2.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer c
    ON cr2.cr_refunded_customer_sk = c.c_customer_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE i.i_category = 'sports-apparel'
  AND r.r_reason_desc LIKE '%damaged%'
  AND cc.cc_state = 'CA'
  AND w.w_city = 'Los Angeles'
  AND sm.sm_carrier = 'FedEx'
  AND wp.wp_type = 'article'
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    i.i_item_id,
    i.i_category,
    i.i_class,
    r.r_reason_desc,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    wp.wp_type,
    ca.total_cat_return_amount
ORDER BY total_web_return_amt DESC
LIMIT 100

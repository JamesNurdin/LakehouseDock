WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        SUM(cs_ext_sales_price) AS total_sales_price,
        SUM(cs_quantity) AS total_quantity
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450815 AND 2451174
      AND cs_ext_sales_price > 100
    GROUP BY cs_item_sk, cs_order_number
)
SELECT
    ca.ca_city,
    cd.cd_gender,
    cc.cc_name,
    cp.cp_description,
    w.w_warehouse_name,
    s.s_store_name,
    r.r_reason_desc,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cs_agg.total_sales_price,
    cs_agg.total_quantity,
    (
        SELECT MAX(w2.w_warehouse_sq_ft)
        FROM warehouse w2
        WHERE w2.w_state = 'CA'
    ) AS max_ca_warehouse_sq_ft
FROM cs_agg
JOIN catalog_returns cr
    ON cr.cr_order_number = cs_agg.cs_order_number
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = cr.cr_order_number
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
WHERE cc.cc_name = 'Northwest Call Center'
  AND cp.cp_catalog_page_number IN (8, 9, 16)
  AND w.w_state = 'CA'
  AND s.s_state = 'TX'
  AND r.r_reason_desc LIKE '%defect%'
GROUP BY
    ca.ca_city,
    cd.cd_gender,
    cc.cc_name,
    cp.cp_description,
    w.w_warehouse_name,
    s.s_store_name,
    r.r_reason_desc,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cs_agg.total_sales_price,
    cs_agg.total_quantity
ORDER BY cs_agg.total_sales_price DESC
LIMIT 100

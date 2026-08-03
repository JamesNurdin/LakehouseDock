WITH item_return_agg AS (
    SELECT
        cr.cr_item_sk,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY cr.cr_item_sk, i.i_category
)
SELECT
    s.s_store_name,
    td.t_hour,
    ca.ca_state,
    cd.cd_gender,
    p.p_promo_name,
    CASE
        WHEN ira.total_return_amount > 1000 THEN 'High'
        ELSE 'Low'
    END AS return_level,
    SUM(sr.sr_return_amt) AS store_return_total,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_txns,
    COUNT(DISTINCT ira.cr_item_sk) AS distinct_items_returned
FROM store_returns sr
RIGHT OUTER JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
LEFT JOIN item i ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
LEFT JOIN item_return_agg ira ON i.i_item_sk = ira.cr_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_time_sk = td.t_time_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
    SELECT 1 FROM promotion p2
    WHERE p2.p_promo_id = p.p_promo_id
      AND p2.p_discount_active = 'Y'
)
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_name,
    td.t_hour,
    ca.ca_state,
    cd.cd_gender,
    p.p_promo_name,
    CASE
        WHEN ira.total_return_amount > 1000 THEN 'High'
        ELSE 'Low'
    END
ORDER BY store_return_total DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

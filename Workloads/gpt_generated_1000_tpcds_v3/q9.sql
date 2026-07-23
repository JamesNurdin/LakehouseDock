SELECT 
    concat(w.w_city, ', ', w.w_state) AS location,
    r.r_reason_desc,
    sum(cr.cr_return_amount) AS total_return_amount,
    count(*) AS return_count,
    avg(cr.cr_return_amount) AS avg_return_amount,
    max(regexp_extract(c.c_email_address, '@(.+)$', 1)) AS email_domain,
    (SELECT avg(cr2.cr_return_amount) FROM catalog_returns cr2) AS overall_avg_return
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE 
    regexp_like(cp.cp_description, '(?i)sale|discount')
    AND c.c_email_address LIKE '%@gmail.com'
    AND EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = c.c_customer_sk
          AND ws.ws_net_paid > 1000
    )
GROUP BY concat(w.w_city, ', ', w.w_state), r.r_reason_desc
HAVING sum(cr.cr_return_amount) > (SELECT avg(cr3.cr_return_amount) FROM catalog_returns cr3)
ORDER BY total_return_amount DESC
LIMIT 100

WITH reason_agg AS (
        SELECT r.r_reason_sk,
               COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
               SUM(cr.cr_return_amount)          AS catalog_return_sum
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_return_amount > 10
        GROUP BY r.r_reason_sk
    )
SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    w.w_warehouse_id,
    w.w_city,
    hd.hd_buy_potential,
    r.r_reason_desc,
    SUM(cr.cr_return_amount)                         AS total_catalog_return,
    SUM(sr.sr_return_amt)                            AS total_store_return,
    SUM(wr.wr_return_amt)                            AS total_web_return,
    COUNT(DISTINCT cr.cr_order_number)               AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number)              AS store_tickets,
    COUNT(DISTINCT wr.wr_order_number)               AS web_orders,
    CASE
        WHEN hd.hd_buy_potential = 'Unknown' THEN 0
        WHEN hd.hd_buy_potential = '>10000' THEN 5
        ELSE 1
    END                                               AS buy_potential_score,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(cr.cr_return_amount) DESC) AS warehouse_return_rank,
    (SELECT MAX(cp2.cp_catalog_page_number)
       FROM catalog_page cp2
       WHERE cp2.cp_department = cp.cp_department)                     AS max_page_number_in_dept,
    MAX(ra.catalog_return_sum)                      AS reason_catalog_return_sum
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN reason_agg ra ON ra.r_reason_sk = r.r_reason_sk
WHERE cp.cp_department = 'Books'
  AND w.w_city = 'Riverside'
  AND hd.hd_buy_potential IN ('5001-10000', '>10000')
  AND r.r_reason_desc LIKE '%defect%'
  AND cr.cr_returned_date_sk BETWEEN 20210101 AND 20211231
GROUP BY
    cp.cp_department,
    cp.cp_catalog_number,
    w.w_warehouse_id,
    w.w_city,
    hd.hd_buy_potential,
    r.r_reason_desc,
    hd.hd_demo_sk,
    cp.cp_department
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_catalog_return DESC
LIMIT 100

WITH overall_avg AS (
  SELECT AVG(cr_reversed_charge) AS avg_rev_charge
  FROM catalog_returns
)
SELECT
    td.t_shift AS shift,
    td.t_sub_shift AS sub_shift,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS returns_cnt,
    overall_avg.avg_rev_charge AS avg_rev_charge_overall
FROM catalog_returns cr
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
CROSS JOIN overall_avg
WHERE td.t_shift = 'first'
  AND td.t_minute IN (10, 12, 13)
  AND cr.cr_refunded_addr_sk IN (
        SELECT cr2.cr_refunded_addr_sk
        FROM catalog_returns cr2
        WHERE cr2.cr_return_tax > 50
    )
GROUP BY td.t_shift, td.t_sub_shift, overall_avg.avg_rev_charge

UNION ALL

SELECT
    td.t_shift AS shift,
    td.t_sub_shift AS sub_shift,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS returns_cnt,
    overall_avg.avg_rev_charge AS avg_rev_charge_overall
FROM catalog_returns cr
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
CROSS JOIN overall_avg
WHERE td.t_shift = 'second'
  AND td.t_minute IN (3, 9)
  AND cr.cr_refunded_addr_sk IN (
        SELECT cr2.cr_refunded_addr_sk
        FROM catalog_returns cr2
        WHERE cr2.cr_return_tax > 50
    )
GROUP BY td.t_shift, td.t_sub_shift, overall_avg.avg_rev_charge
ORDER BY shift, total_return_amount DESC
LIMIT 100

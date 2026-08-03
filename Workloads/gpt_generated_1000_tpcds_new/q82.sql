WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_refunded_cash,
        cr.cr_store_credit,
        cr.cr_return_ship_cost,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_catalog_page_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 50.00
      AND cr.cr_refunded_cash < 500.00
      AND cr.cr_return_quantity >= 1
      AND cr.cr_return_ship_cost > 0
      AND cr.cr_returned_date_sk BETWEEN 2450900 AND 2451300
      AND cr.cr_returned_time_sk IS NOT NULL
)
SELECT
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.cp_catalog_number,
    COUNT(fr.cr_return_amount) AS returns_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_refunded_cash) AS avg_refunded_cash,
    MIN(fr.cr_return_ship_cost) AS min_ship_cost,
    MAX(fr.cr_return_quantity) AS max_return_qty,
    SUM(CASE WHEN fr.cr_return_amount > 500 THEN fr.cr_return_amount ELSE 0 END) AS high_return_total,
    SUM(CASE WHEN fr.cr_net_loss < 0 THEN fr.cr_net_loss ELSE 0 END) AS total_negative_loss
FROM filtered_returns fr
JOIN catalog_page cp
    ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_department = 'Electronics'
  AND cp.cp_catalog_number BETWEEN 100 AND 200
  AND cp.cp_catalog_page_number IN (6, 14, 20)
  AND cp.cp_start_date_sk >= 2450900
  AND cp.cp_start_date_sk <= 2451200
GROUP BY
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.cp_catalog_number
ORDER BY total_return_amount DESC
LIMIT 100

/* goal: Identify which catalog departments and return reasons generate the highest monetary losses, broken down by department and reason, after applying multiple realistic filters on return transactions. */
WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_reversed_charge,
        cr_store_credit,
        cr_returning_addr_sk,
        cr_order_number,
        cr_catalog_page_sk,
        cr_reason_sk
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450900 AND 2451300
      AND cr_return_quantity >= 2
      AND cr_return_amount > 10
      AND cr_reversed_charge < 100
      AND cr_store_credit >= 20
      AND cr_returning_addr_sk = 5312421
)
SELECT
    cp.cp_department,
    r.r_reason_desc,
    COUNT(DISTINCT fr.cr_order_number) AS orders_returned,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_reversed_charge) AS avg_reversed_charge,
    MIN(fr.cr_return_quantity) AS min_quantity,
    MAX(fr.cr_return_quantity) AS max_quantity
FROM filtered_returns fr
JOIN catalog_page cp
    ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
    ON fr.cr_reason_sk = r.r_reason_sk
WHERE cp.cp_catalog_page_number IN (3, 8, 13)
  AND cp.cp_start_date_sk >= 2450990
  AND r.r_reason_id LIKE 'AAAA%'
GROUP BY cp.cp_department, r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100

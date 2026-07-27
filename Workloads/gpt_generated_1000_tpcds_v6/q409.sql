WITH avg_rev_charge AS (
    SELECT AVG(cr_reversed_charge) AS avg_rev_charge
    FROM catalog_returns
)
SELECT
    cr.cr_returning_hdemo_sk,
    hd.hd_buy_potential,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    MIN(cr.cr_return_quantity) AS min_quantity,
    MAX(cr.cr_return_amt_inc_tax) AS max_amt_inc_tax
FROM catalog_returns cr
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    AND c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE cr.cr_ship_mode_sk IN (17, 20, 4)
  AND cr.cr_reversed_charge > (SELECT avg_rev_charge FROM avg_rev_charge)
  AND cr.cr_refunded_cash BETWEEN 100 AND 1000
  AND c.c_current_addr_sk = 297266
  AND hd.hd_dep_count >= 4
GROUP BY ROLLUP(cr.cr_returning_hdemo_sk, hd.hd_buy_potential)
ORDER BY total_return_amount DESC
LIMIT 100

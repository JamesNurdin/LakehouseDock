SELECT
    sm.sm_ship_mode_id,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_quantity,
    CONCAT('Contract_', sm.sm_contract) AS contract_label,
    (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS overall_avg_net_loss
FROM catalog_returns cr
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE regexp_like(sm.sm_contract, '^A.*[0-9]{2}$')
  AND cd.cd_credit_rating LIKE '%A%'
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN web_page wp
          ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE wp.wp_web_page_id LIKE 'AAAAAAA%'
          AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
          AND regexp_extract(wp.wp_url, 'promo[0-9]+') IS NOT NULL
    )
GROUP BY sm.sm_ship_mode_id, sm.sm_contract
ORDER BY total_net_loss DESC
LIMIT 100

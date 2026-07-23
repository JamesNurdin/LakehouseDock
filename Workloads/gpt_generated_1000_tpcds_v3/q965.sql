WITH store_ret_filtered AS (
    SELECT
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_meal_time = 'lunch'
      AND sr.sr_return_quantity > 1
)
SELECT
    cc.cc_name AS call_center_name,
    cp.cp_type AS catalog_page_type,
    cd.cd_gender AS customer_gender,
    t.t_hour AS hour_of_day,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_return_quantity) + SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(sr.sr_return_quantity) AS avg_store_return_quantity,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customer_count,
    MAX(sr.sr_return_amt) AS max_store_return_amount,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS overall_avg_catalog_return_amount
FROM store_ret_filtered sr
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
WHERE cc.cc_state = 'CA'
  AND cp.cp_type = 'monthly'
  AND c.c_last_name = 'Williams'
GROUP BY
    cc.cc_name,
    cp.cp_type,
    cd.cd_gender,
    t.t_hour
HAVING SUM(cr.cr_return_amount) > (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2)
ORDER BY total_catalog_return_amount DESC
LIMIT 100

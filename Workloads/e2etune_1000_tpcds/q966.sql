SELECT
    sm.sm_type AS ship_mode,
    ca.ca_state AS state,
    cd.cd_gender AS gender,
    COUNT(DISTINCT cr.cr_order_number) AS return_cnt,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(cr.cr_net_loss) / NULLIF(SUM(cs.cs_net_profit), 0) AS loss_to_profit_ratio,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_quantity) AS total_quantity_returned
FROM catalog_returns AS cr
JOIN catalog_sales AS cs
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN ship_mode AS sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address AS ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics AS cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics AS hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
  AND cd.cd_gender = 'F'
  AND hd.hd_income_band_sk BETWEEN 5 AND 7
GROUP BY sm.sm_type, ca.ca_state, cd.cd_gender
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY loss_to_profit_ratio DESC
LIMIT 10

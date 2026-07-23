WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_paid
    FROM catalog_sales cs
    WHERE cs.cs_ship_customer_sk = 8788740
      AND cs.cs_ext_list_price > 5000.00
)
SELECT
    td.t_hour,
    cd.cd_gender,
    hd.hd_buy_potential,
    COUNT(DISTINCT cr.cr_order_number) AS order_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    AVG(fs.cs_net_paid) AS avg_net_paid,
    MAX(cr.cr_store_credit) AS max_store_credit,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS overall_avg_return_amount
FROM catalog_returns cr
JOIN filtered_sales fs
    ON cr.cr_item_sk = fs.cs_item_sk
   AND cr.cr_order_number = fs.cs_order_number
JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
JOIN store_returns sr
    ON td.t_time_sk = sr.sr_return_time_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE cr.cr_store_credit > 50.00
  AND cr.cr_returning_cdemo_sk IN (640677, 452924)
  AND td.t_sub_shift = 'morning'
GROUP BY td.t_hour, cd.cd_gender, hd.hd_buy_potential
HAVING SUM(cr.cr_return_amount) > 1000.00
ORDER BY total_return_amount DESC
LIMIT 100

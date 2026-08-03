WITH filtered_catalog AS (
    SELECT cr_returned_date_sk,
           cr_item_sk,
           cr_refunded_customer_sk,
           cr_refunded_cdemo_sk,
           cr_refunded_hdemo_sk,
           cr_reason_sk,
           cr_return_amount,
           cr_return_quantity,
           cr_net_loss,
           cr_reversed_charge,
           cr_order_number
    FROM catalog_returns
    WHERE cr_reversed_charge > 50
      AND cr_return_amount > 0
)
SELECT
    d.d_year AS year,
    i.i_brand AS brand,
    cd.cd_gender AS gender,
    hd.hd_buy_potential AS buy_potential,
    CASE WHEN ib.ib_income_band_sk >= 15 THEN 'HighIncome' ELSE 'LowIncome' END AS income_category,
    COUNT(DISTINCT fc.cr_order_number) AS distinct_orders,
    SUM(fc.cr_return_amount) AS total_catalog_return_amount,
    AVG(sr.sr_return_amt) AS avg_store_return_amount,
    MAX(fc.cr_net_loss) AS max_net_loss,
    MIN(fc.cr_return_quantity) AS min_return_qty,
    (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return_amount
FROM store_returns sr
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN filtered_catalog fc
  ON fc.cr_returned_date_sk = d.d_date_sk
 AND fc.cr_item_sk = i.i_item_sk
 AND fc.cr_refunded_customer_sk = c.c_customer_sk
 AND fc.cr_refunded_cdemo_sk = cd.cd_demo_sk
 AND fc.cr_refunded_hdemo_sk = hd.hd_demo_sk
 AND fc.cr_reason_sk = r.r_reason_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
 AND wp.wp_creation_date_sk = d.d_date_sk
 AND wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND c.c_birth_month = 7
  AND hd.hd_buy_potential = '501-1000'
  AND ib.ib_lower_bound >= 30000
  AND r.r_reason_desc LIKE '%damaged%'
GROUP BY d.d_year,
         i.i_brand,
         cd.cd_gender,
         hd.hd_buy_potential,
         CASE WHEN ib.ib_income_band_sk >= 15 THEN 'HighIncome' ELSE 'LowIncome' END
ORDER BY total_catalog_return_amount DESC
LIMIT 100

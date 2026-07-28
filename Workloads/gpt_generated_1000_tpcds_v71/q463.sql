WITH filtered_returns AS (
    SELECT
        cr.cr_return_tax,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_returning_customer_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_returning_hdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_tax > 10.00
      AND cr.cr_return_amount < 500.00
), filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_year
    FROM customer c
    WHERE c.c_birth_year BETWEEN 1970 AND 1980
), filtered_ship_mode AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_contract,
        sm.sm_code
    FROM ship_mode sm
    WHERE sm.sm_contract = 'HVDFCcQ'
      AND sm.sm_code = 'AIR'
), filtered_catalog_page AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department
    FROM catalog_page cp
    WHERE cp.cp_department = 'Electronics'
)
SELECT
    cp.cp_department,
    sm.sm_ship_mode_id,
    CASE WHEN fr.cr_return_tax > 100 THEN 'High Tax' ELSE 'Low Tax' END AS tax_category,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(ss.ss_net_profit) AS avg_store_profit,
    COUNT(DISTINCT fc.c_customer_id) AS unique_customers
FROM filtered_returns fr
JOIN filtered_catalog_page cp
  ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN filtered_ship_mode sm
  ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN filtered_customers fc
  ON fr.cr_returning_customer_sk = fc.c_customer_sk
JOIN customer_demographics cd
  ON fr.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON fr.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN store_sales ss
  ON ss.ss_customer_sk = fc.c_customer_sk
 AND ss.ss_cdemo_sk = cd.cd_demo_sk
 AND ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_customer_sk = fc.c_customer_sk
      AND wp.wp_type = 'Home'
      AND wp.wp_rec_start_date >= DATE '2022-01-01'
)
GROUP BY
    cp.cp_department,
    sm.sm_ship_mode_id,
    CASE WHEN fr.cr_return_tax > 100 THEN 'High Tax' ELSE 'Low Tax' END
ORDER BY total_net_loss DESC
LIMIT 100

WITH high_returns AS (
    SELECT c.c_customer_id,
           'WEB' AS return_type,
           SUM(wr.wr_return_amt) AS total_return
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE wr.wr_return_amt > 50
    GROUP BY c.c_customer_id

    UNION ALL

    SELECT c.c_customer_id,
           'CATALOG' AS return_type,
           SUM(cr.cr_return_amount) AS total_return
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_amount > 50
    GROUP BY c.c_customer_id
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    ib.ib_income_band_sk,
    r.r_reason_desc,
    cp.cp_department,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_catalog_return,
    SUM(wr.wr_return_amt) AS total_web_return,
    AVG(ib.ib_lower_bound) AS avg_income_lower,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2 WHERE cr2.cr_return_amount > 0) AS avg_catalog_return,
    MAX(hr.total_return) AS max_high_return
FROM store_sales ss
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returning_customer_sk = c.c_customer_sk
 AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
 AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_returns wr
  ON wr.wr_returning_customer_sk = c.c_customer_sk
 AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
 AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
 AND wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN high_returns hr
  ON hr.c_customer_id = c.c_customer_id
WHERE
    cp.cp_catalog_page_number IN (5, 13)
    AND cd.cd_gender = 'F'
    AND ib.ib_upper_bound > 50000
    AND r.r_reason_id = 'AAAAAAAADAAAAAAA'
    AND ss.ss_sold_date_sk BETWEEN 2450905 AND 2451145
    AND wr.wr_reversed_charge > 10.00
GROUP BY
    c.c_customer_id,
    cd.cd_gender,
    ib.ib_income_band_sk,
    r.r_reason_desc,
    cp.cp_department
ORDER BY total_sales DESC
LIMIT 100

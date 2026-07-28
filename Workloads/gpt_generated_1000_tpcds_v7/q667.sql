WITH sales_demo AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_coupon_amt,
        ss.ss_ext_discount_amt,
        ss.ss_cdemo_sk,
        cd.cd_gender,
        cd.cd_education_status,
        s.s_store_name,
        s.s_number_employees,
        s.s_country
    FROM tpcds.store_sales ss
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_country = 'United States'
      AND s.s_number_employees > 200
      AND ss.ss_coupon_amt > 100
      AND ss.ss_ext_discount_amt < 200
      AND cd.cd_gender = 'M'
)
SELECT
    sd.s_store_name,
    sd.cd_education_status,
    COUNT(DISTINCT sd.ss_ticket_number) AS distinct_tickets,
    SUM(sd.ss_net_paid) AS total_net_paid,
    AVG(sd.ss_coupon_amt) AS avg_coupon_amt,
    MAX(sd.ss_ext_discount_amt) AS max_discount_amt,
    SUM(wr.wr_net_loss) AS total_return_loss
FROM sales_demo sd
JOIN tpcds.web_returns wr
    ON wr.wr_refunded_cdemo_sk = sd.ss_cdemo_sk
WHERE wr.wr_return_amt_inc_tax > 500
  AND wr.wr_fee < 50
GROUP BY
    sd.s_store_name,
    sd.cd_education_status
ORDER BY total_net_paid DESC
LIMIT 20

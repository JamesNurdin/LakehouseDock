WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_store_name,
    cd.cd_gender,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    COUNT(DISTINCT ca.ca_zip) AS distinct_zip_codes,
    MIN(ss.ss_ext_tax) AS min_tax,
    MAX(ss.ss_ext_tax) AS max_tax
FROM sampled_sales ss
FULL OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
INNER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
INNER JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
WHERE
    cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'S'
    AND cd.cd_purchase_estimate > 5000
    AND s.s_state = 'CA'
    AND s.s_gmt_offset = -8.00
    AND ss.ss_ext_discount_amt > 100
    AND ss.ss_coupon_amt = 0.00
    AND ca.ca_city = 'Elm'
GROUP BY GROUPING SETS (
    (s.s_store_name, cd.cd_gender),
    (s.s_store_name),
    (cd.cd_gender),
    ()
)
ORDER BY total_net_paid DESC
OFFSET 20 ROWS FETCH NEXT 100 ROWS ONLY

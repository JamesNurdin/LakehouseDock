WITH high_value_customers AS (
    SELECT ss_customer_sk FROM store_sales WHERE ss_coupon_amt > 2000
    INTERSECT
    SELECT sr_customer_sk FROM store_returns WHERE sr_return_amt > 500
),
overall_avg_coupon AS (
    SELECT AVG(ss_coupon_amt) AS overall_avg FROM store_sales
)
SELECT
    d.d_date,
    c.c_last_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    r.r_reason_desc,
    cp.cp_type,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_coupon_amt) AS avg_coupon,
    COUNT(DISTINCT ss.ss_ticket_number) AS txn_count,
    MIN(sr.sr_return_amt) AS min_return_amt,
    MAX(ib.ib_upper_bound) AS max_income_upper,
    MAX(overall_avg_coupon.overall_avg) AS overall_avg,
    rc.return_cnt,
    ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS rn
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
JOIN high_value_customers hvc ON ss.ss_customer_sk = hvc.ss_customer_sk
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS return_cnt
    FROM store_returns sr2
    WHERE sr2.sr_customer_sk = ss.ss_customer_sk
      AND sr2.sr_return_amt > 0
) rc ON TRUE
CROSS JOIN overall_avg_coupon
WHERE
    c.c_last_name IN ('Small', 'Bowen', 'Hill')
    AND d.d_year = 2002
    AND t.t_hour BETWEEN 9 AND 17
    AND cp.cp_description LIKE '%econom%'
    AND ss.ss_coupon_amt > 1000
    AND ss.ss_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_preferred_cust_flag = 'Y')
GROUP BY
    d.d_date,
    c.c_last_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    r.r_reason_desc,
    cp.cp_type,
    rc.return_cnt
ORDER BY total_net_paid DESC
LIMIT 100

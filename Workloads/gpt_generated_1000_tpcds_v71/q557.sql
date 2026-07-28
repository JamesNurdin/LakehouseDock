WITH base_facts AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_store_credit,
        sr.sr_return_quantity,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        hd.hd_buy_potential,
        ca.ca_city,
        s.s_state,
        r.r_reason_desc,
        s.s_store_name,
        s.s_tax_percentage
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
)
SELECT
    s2.s_store_name,
    s3.s_tax_percentage,
    ca2.ca_city,
    hd2.hd_buy_potential,
    r2.r_reason_desc,
    s_main.s_state,
    SUM(bf.sr_return_amt)          AS total_return_amt,
    AVG(bf.sr_return_tax)          AS avg_return_tax,
    COUNT(*)                       AS return_cnt
FROM base_facts bf
JOIN household_demographics hd2
    ON bf.sr_hdemo_sk = hd2.hd_demo_sk
JOIN customer_address ca2
    ON bf.sr_addr_sk = ca2.ca_address_sk
JOIN store s2
    ON bf.sr_store_sk = s2.s_store_sk
JOIN store s3
    ON bf.sr_store_sk = s3.s_store_sk
JOIN store s_main
    ON bf.sr_store_sk = s_main.s_store_sk
JOIN reason r2
    ON bf.sr_reason_sk = r2.r_reason_sk
GROUP BY
    GROUPING SETS (
        (s2.s_store_name, s3.s_tax_percentage, ca2.ca_city, hd2.hd_buy_potential, r2.r_reason_desc, s_main.s_state),
        (s2.s_store_name, s3.s_tax_percentage, ca2.ca_city, hd2.hd_buy_potential, s_main.s_state),
        (s2.s_store_name, s3.s_tax_percentage, hd2.hd_buy_potential, s_main.s_state),
        (s2.s_store_name, s_main.s_state),
        ()
    )
ORDER BY total_return_amt DESC
LIMIT 100

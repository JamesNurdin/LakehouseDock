WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_ext_discount_amt,
        ss.ss_ext_tax,
        ss.ss_net_paid,
        ss.ss_ext_wholesale_cost,
        s.s_store_id,
        s.s_state,
        s.s_gmt_offset,
        ca.ca_state,
        ca.ca_gmt_offset,
        hd.hd_dep_count,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ca.ca_state = 'CA'
      AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
      AND s.s_state = 'CA'
      AND s.s_gmt_offset BETWEEN -5.00 AND 5.00
      AND hd.hd_dep_count <= 5
      AND hd.hd_buy_potential = '1001-5000'
      AND ib.ib_lower_bound >= 100000
      AND ss.ss_ext_discount_amt > 0
      AND ss.ss_ext_tax < 200
)
SELECT
    s_store_id,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_ext_discount_amt) AS avg_discount,
    COUNT(*) AS txn_count,
    MIN(ss_ext_tax) AS min_tax,
    MAX(ss_ext_wholesale_cost) AS max_wholesale_cost
FROM filtered_sales
GROUP BY
    s_store_id,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound
HAVING
    SUM(ss_net_paid) > 10000
    AND COUNT(*) >= 10
ORDER BY total_net_paid DESC
LIMIT 100

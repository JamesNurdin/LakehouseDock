WITH agg_returns AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_hdemo_sk,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        MIN(sr.sr_return_amt) AS min_return_amt,
        MAX(sr.sr_return_amt) AS max_return_amt
    FROM store_returns AS sr
    WHERE sr.sr_return_ship_cost > 20.00
      AND sr.sr_reversed_charge < 10.00
      AND sr.sr_return_tax BETWEEN 1.00 AND 5.00
    GROUP BY sr.sr_customer_sk, sr.sr_hdemo_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    SUM(ar.return_cnt) AS total_returns,
    SUM(ar.total_net_loss) AS total_net_loss,
    AVG(ar.avg_return_amt) AS overall_avg_return_amt,
    MIN(ar.min_return_amt) AS overall_min_return_amt,
    MAX(ar.max_return_amt) AS overall_max_return_amt
FROM agg_returns AS ar
JOIN customer AS c
  ON ar.sr_customer_sk = c.c_customer_sk
JOIN household_demographics AS hd
  ON ar.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE c.c_birth_year BETWEEN 1970 AND 1990
  AND c.c_preferred_cust_flag = 'Y'
  AND hd.hd_dep_count <= 2
  AND hd.hd_buy_potential = '>10000'
  AND ib.ib_upper_bound <= 100000
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential
ORDER BY total_net_loss DESC
LIMIT 100

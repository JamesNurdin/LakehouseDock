WITH cs AS (
   SELECT
       t.t_hour,
       hd.hd_demo_sk,
       hd.hd_buy_potential,
       t.t_shift,
       SUM(cs.cs_net_profit) AS cs_profit,
       COUNT(*) AS cs_cnt
   FROM catalog_sales cs
   JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE regexp_like(hd.hd_buy_potential, '^A[0-9]{2}$')
     AND t.t_shift LIKE 'first%'
   GROUP BY t.t_hour, hd.hd_demo_sk, hd.hd_buy_potential, t.t_shift
),
ss AS (
   SELECT
       t.t_hour,
       hd.hd_demo_sk,
       hd.hd_buy_potential,
       t.t_shift,
       SUM(ss.ss_net_profit) AS ss_profit,
       COUNT(*) AS ss_cnt
   FROM store_sales ss
   JOIN time_dim t
     ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE regexp_like(hd.hd_buy_potential, '^A[0-9]{2}$')
     AND t.t_shift LIKE 'first%'
   GROUP BY t.t_hour, hd.hd_demo_sk, hd.hd_buy_potential, t.t_shift
)
SELECT
    cs.t_hour,
    CONCAT(cs.t_shift, '-', cs.hd_buy_potential) AS shift_buy,
    (cs.cs_profit + ss.ss_profit) AS total_profit,
    (cs.cs_cnt + ss.ss_cnt) AS total_transactions
FROM cs
JOIN ss
  ON cs.t_hour = ss.t_hour
 AND cs.hd_demo_sk = ss.hd_demo_sk
 AND cs.t_shift = ss.t_shift
 AND cs.hd_buy_potential = ss.hd_buy_potential
ORDER BY total_profit DESC
LIMIT 100

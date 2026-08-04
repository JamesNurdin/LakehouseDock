WITH store_full AS (
   SELECT 
       ss.ss_store_sk,
       ss.ss_cdemo_sk,
       ss.ss_hdemo_sk,
       ss.ss_quantity,
       ss.ss_net_paid,
       ss.ss_net_profit,
       s.s_store_name,
       s.s_state
   FROM store_sales ss
   FULL OUTER JOIN store s
       ON ss.ss_store_sk = s.s_store_sk
)
SELECT
   sf.s_store_name,
   sf.s_state,
   cd.cd_gender,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   COUNT(DISTINCT sf.ss_store_sk)                                   AS store_cnt,
   SUM(sf.ss_quantity)                                             AS total_qty,
   AVG(sf.ss_net_paid)                                             AS avg_net_paid,
   SUM(CASE WHEN ib.ib_upper_bound > 100000 THEN sf.ss_net_profit ELSE 0 END) AS profit_high_income,
   COUNT(DISTINCT excl.cust_sk)                                    AS catalog_exclusive_customers,
   SUM(cs.cs_net_paid_inc_ship)                                    AS total_catalog_sales,
   SUM(ws.ws_net_paid_inc_ship)                                    AS total_web_sales
FROM store_full sf
JOIN customer_demographics cd
   ON sf.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
   ON sf.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
   ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_sales cs
   ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
LEFT JOIN web_sales ws
   ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
LEFT JOIN (
   SELECT cs.cs_bill_customer_sk AS cust_sk
   FROM catalog_sales cs
   EXCEPT
   SELECT ws.ws_bill_customer_sk FROM web_sales ws
) excl
   ON cs.cs_bill_customer_sk = excl.cust_sk
WHERE
   ib.ib_lower_bound >= 40000
   AND ib.ib_upper_bound <= 120000
   AND sf.ss_quantity > 1
   AND cd.cd_gender = 'M'
   AND sf.s_state IN ('CA', 'TX', 'NY')
GROUP BY
   sf.s_store_name,
   sf.s_state,
   cd.cd_gender,
   ib.ib_lower_bound,
   ib.ib_upper_bound
ORDER BY total_qty DESC
LIMIT 100

WITH base AS (
   SELECT
        cs.cs_ext_sales_price        AS cs_sales,
        cs.cs_net_profit             AS cs_profit,
        ss.ss_ext_sales_price        AS ss_sales,
        ss.ss_net_profit             AS ss_profit,
        ws.ws_ext_sales_price        AS ws_sales,
        ws.ws_net_profit             AS ws_profit,
        sr.sr_return_amt_inc_tax     AS sr_return,
        sr.sr_net_loss               AS sr_loss,
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_type,
        t.t_hour,
        t.t_am_pm,
        ca.ca_state
   FROM catalog_sales cs
   JOIN time_dim t               ON cs.cs_sold_time_sk   = t.t_time_sk
   JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk   = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk   = hd.hd_demo_sk
   LEFT JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN ship_mode sm        ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
   LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk   = ca.ca_address_sk
   JOIN store_sales ss
        ON ss.ss_sold_time_sk   = t.t_time_sk
       AND ss.ss_customer_sk    = c.c_customer_sk
   JOIN web_sales ws
        ON ws.ws_sold_time_sk   = t.t_time_sk
       AND ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
       AND sr.sr_customer_sk   = c.c_customer_sk
   WHERE cs.cs_ext_sales_price > 500
     AND sr.sr_return_amt_inc_tax < 2000
     AND ib.ib_lower_bound >= 30000
     AND t.t_hour BETWEEN 9 AND 17
     AND cd.cd_gender = 'M'
)
SELECT
   gender,
   income_band,
   SUM(total_sales)   AS total_sales,
   AVG(total_profit)  AS avg_profit,
   SUM(total_returns) AS total_returns,
   COUNT(*)           AS cnt
FROM (
   SELECT
        cd_gender               AS gender,
        ib_lower_bound          AS income_band,
        (cs_sales + ss_sales + ws_sales) AS total_sales,
        (cs_profit + ss_profit + ws_profit) AS total_profit,
        sr_return               AS total_returns,
        c_customer_sk
   FROM base b
   WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = b.c_customer_sk
          AND sr2.sr_net_loss > 100
   )
) sub
GROUP BY GROUPING SETS (
    (gender, income_band),
    (gender),
    ()
)
ORDER BY total_sales DESC
LIMIT 100

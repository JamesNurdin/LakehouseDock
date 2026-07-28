WITH filtered_stores AS (
   SELECT
       s.s_store_sk,
       s.s_store_name,
       s.s_city,
       s.s_state,
       CONCAT(s.s_state, '-', s.s_city) AS location
   FROM store s
   WHERE regexp_like(s.s_store_name, 'Mart$')
     AND s.s_state LIKE 'N%'
),
store_sales_agg AS (
   SELECT
       fs.location,
       SUM(ss.ss_net_profit) AS profit,
       COUNT(*) AS txn_cnt,
       d.d_year
   FROM store_sales ss
   JOIN filtered_stores fs ON ss.ss_store_sk = fs.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year = 2021
     AND regexp_like(cd.cd_credit_rating, '^A')
     AND EXISTS (
         SELECT 1
         FROM catalog_returns cr
         WHERE cr.cr_refunded_hdemo_sk = ss.ss_hdemo_sk
           AND cr.cr_returned_date_sk = d.d_date_sk
     )
   GROUP BY fs.location, d.d_year
),
web_sales_agg AS (
   SELECT
       CONCAT(w.w_state, '-', w.w_city) AS location,
       SUM(ws.ws_net_profit) AS profit,
       COUNT(*) AS txn_cnt,
       d.d_year
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year = 2021
     AND regexp_like(w.w_warehouse_name, '^WH')
     AND regexp_like(cd.cd_credit_rating, '^A')
   GROUP BY CONCAT(w.w_state, '-', w.w_city), d.d_year
),
combined AS (
   SELECT location, profit, txn_cnt, d_year FROM store_sales_agg
   UNION ALL
   SELECT location, profit, txn_cnt, d_year FROM web_sales_agg
)
SELECT
    c.location,
    SUM(c.profit) AS total_profit,
    SUM(c.txn_cnt) AS total_transactions,
    RANK() OVER (ORDER BY SUM(c.profit) DESC) AS profit_rank,
    (SELECT AVG(profit) FROM combined) AS avg_profit_all_locations
FROM combined c
GROUP BY c.location
HAVING SUM(c.profit) > (SELECT AVG(profit) FROM combined)
ORDER BY total_profit DESC
LIMIT 100

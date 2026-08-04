WITH sales_profit AS (
   SELECT ws.ws_bill_customer_sk AS customer_sk,
          SUM(ws.ws_net_profit) AS profit
   FROM web_sales ws
   TABLESAMPLE BERNOULLI (5)   -- sample 5% of rows
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
   GROUP BY ws.ws_bill_customer_sk
),
return_loss AS (
   SELECT cr.cr_refunded_customer_sk AS customer_sk,
          -SUM(cr.cr_net_loss) AS profit
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
   GROUP BY cr.cr_refunded_customer_sk
),
combined_profit AS (
   SELECT * FROM sales_profit
   UNION ALL
   SELECT * FROM return_loss
),
agg_profit AS (
   SELECT customer_sk,
          SUM(profit) AS total_profit
   FROM combined_profit
   GROUP BY customer_sk
   HAVING SUM(profit) > 0
),
customers_no_web_return AS (
   SELECT c.c_customer_sk,
          c.c_customer_id,
          c.c_first_name,
          c.c_last_name
   FROM customer c
   WHERE NOT EXISTS (
         SELECT 1
         FROM web_returns wr
         JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
         WHERE wr.wr_returning_customer_sk = c.c_customer_sk
           AND d2.d_year = 2000
   )
),
final_data AS (
   SELECT cnwr.c_customer_id,
          cnwr.c_first_name,
          cnwr.c_last_name,
          ap.total_profit,
          smodes.modes
   FROM agg_profit ap
   JOIN customers_no_web_return cnwr
     ON ap.customer_sk = cnwr.c_customer_sk
   LEFT JOIN LATERAL (
        SELECT array_agg(DISTINCT sm.sm_ship_mode_id) AS modes
        FROM web_sales ws3
        JOIN ship_mode sm ON ws3.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN date_dim d3 ON ws3.ws_sold_date_sk = d3.d_date_sk
        WHERE ws3.ws_bill_customer_sk = ap.customer_sk
          AND d3.d_year = 2000
   ) smodes ON true
)
SELECT f.c_customer_id,
       f.c_first_name,
       f.c_last_name,
       f.total_profit,
       f.modes
FROM final_data f
EXCEPT
SELECT f2.c_customer_id,
       f2.c_first_name,
       f2.c_last_name,
       f2.total_profit,
       f2.modes
FROM final_data f2
JOIN customer c ON f2.c_customer_id = c.c_customer_id
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'TX'
ORDER BY total_profit DESC

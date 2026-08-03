WITH first_set AS (
   SELECT
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      s.s_store_name,
      SUM(sr.sr_return_amt) AS total_return_amt,
      SUM(ws.ws_net_paid) AS total_web_net_paid,
      SUM(ws.ws_net_paid) - SUM(sr.sr_return_amt) AS diff
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE cd.cd_education_status = 'College'
     AND ca.ca_state = 'CA'
     AND sr.sr_return_amt > 20
     AND ws.ws_quantity > 5
     AND r.r_reason_desc LIKE '%defect%'
     AND c.c_birth_year BETWEEN 1970 AND 1990
   GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, s.s_store_name
),
second_set AS (
   SELECT
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      s.s_store_name,
      SUM(sr.sr_return_amt) AS total_return_amt,
      SUM(ws.ws_net_paid) AS total_web_net_paid,
      SUM(ws.ws_net_paid) - SUM(sr.sr_return_amt) AS diff
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE cd.cd_education_status = 'Advanced Degree'
     AND ca.ca_state = 'NY'
     AND sr.sr_return_amt < 10
     AND ws.ws_quantity <= 5
     AND r.r_reason_desc LIKE '%customer%'
     AND c.c_birth_year BETWEEN 1980 AND 2000
   GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, s.s_store_name
)
SELECT
   customer_id,
   first_name,
   last_name,
   store_name,
   total_return_amt,
   total_web_net_paid,
   diff,
   RANK() OVER (ORDER BY diff DESC) AS revenue_diff_rank
FROM (
   SELECT
      c_customer_id AS customer_id,
      c_first_name AS first_name,
      c_last_name AS last_name,
      s_store_name AS store_name,
      total_return_amt,
      total_web_net_paid,
      diff
   FROM first_set
   EXCEPT
   SELECT
      c_customer_id,
      c_first_name,
      c_last_name,
      s_store_name,
      total_return_amt,
      total_web_net_paid,
      diff
   FROM second_set
) AS diff_set
ORDER BY revenue_diff_rank
LIMIT 100

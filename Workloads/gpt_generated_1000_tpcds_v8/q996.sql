WITH
  base_join AS (
    SELECT
      cs.cs_order_number,
      cs.cs_bill_customer_sk,
      cs.cs_bill_addr_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      td.t_hour,
      c.c_email_address,
      c.c_birth_year,
      ca.ca_state,
      hd.hd_income_band_sk
    FROM catalog_sales cs
    RIGHT OUTER JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 8 AND 17
      AND (c.c_email_address LIKE '%@oX7RpdSqcTn0VP.com' OR c.c_email_address LIKE '%@dx6gJtIxDpul.org')
      AND hd.hd_income_band_sk IN (1, 5, 9)
      AND cs.cs_quantity > 5
  ),
  agg AS (
    SELECT
      bj.cs_bill_customer_sk                                     AS customer_sk,
      SUM(bj.cs_net_profit)                                      AS total_profit,
      SUM(bj.cs_net_paid)                                        AS total_paid,
      COUNT(*)                                                   AS sales_cnt,
      CASE WHEN SUM(bj.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
      MAX(bj.t_hour)                                             AS max_hour,
      bj.ca_state,
      bj.hd_income_band_sk
    FROM base_join bj
    GROUP BY bj.cs_bill_customer_sk, bj.ca_state, bj.hd_income_band_sk
  ),
  profitable AS (
    SELECT * FROM agg WHERE profit_status = 'Profitable'
  ),
  losses AS (
    SELECT * FROM agg WHERE profit_status = 'Loss'
  ),
  union_set AS (
    SELECT customer_sk, total_profit, total_paid, sales_cnt, profit_status, max_hour, ca_state, hd_income_band_sk FROM profitable
    UNION
    SELECT customer_sk, total_profit, total_paid, sales_cnt, profit_status, max_hour, ca_state, hd_income_band_sk FROM losses
  ),
  except_set AS (
    SELECT customer_sk FROM union_set WHERE ca_state = 'CA'
    EXCEPT
    SELECT customer_sk FROM union_set WHERE hd_income_band_sk = 9
  )
SELECT
  us.customer_sk,
  us.total_profit,
  us.total_paid,
  us.sales_cnt,
  us.profit_status,
  us.max_hour,
  us.ca_state,
  us.hd_income_band_sk,
  ROW_NUMBER() OVER (PARTITION BY us.profit_status ORDER BY us.total_profit DESC) AS rn_profit,
  RANK()        OVER (ORDER BY us.total_profit DESC)                     AS profit_rank,
  lt.total_qty
FROM union_set us
CROSS JOIN LATERAL (
  SELECT SUM(cs.cs_quantity) AS total_qty
  FROM catalog_sales cs
  WHERE cs.cs_bill_customer_sk = us.customer_sk
) lt
WHERE us.customer_sk IN (SELECT customer_sk FROM except_set)
ORDER BY us.total_profit DESC
LIMIT 100

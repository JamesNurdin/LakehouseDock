WITH
  store_sales_agg AS (
    SELECT
      ca.ca_state,
      SUM(ss.ss_net_profit)      AS store_sales_profit,
      SUM(ss.ss_net_paid)        AS store_sales_paid
    FROM store_sales ss
    JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
  ),
  store_returns_agg AS (
    SELECT
      ca.ca_state,
      SUM(sr.sr_net_loss)        AS store_returns_loss
    FROM store_returns sr
    JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
  ),
  catalog_sales_agg AS (
    SELECT
      ca.ca_state,
      SUM(cs.cs_net_profit)      AS catalog_sales_profit
    FROM catalog_sales cs
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
  ),
  web_returns_agg AS (
    SELECT
      ca.ca_state,
      SUM(wr.wr_net_loss)        AS web_returns_loss
    FROM web_returns wr
    JOIN customer c               ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
  )
SELECT
  COALESCE(ssa.ca_state, csa.ca_state, sra.ca_state, wra.ca_state) AS state,
  COALESCE(ssa.store_sales_profit, 0) + COALESCE(csa.catalog_sales_profit, 0)
    - COALESCE(sra.store_returns_loss, 0) - COALESCE(wra.web_returns_loss, 0) AS net_profit,
  COALESCE(ssa.store_sales_paid, 0)                         AS store_sales_paid
FROM store_sales_agg   ssa
FULL OUTER JOIN catalog_sales_agg csa ON ssa.ca_state = csa.ca_state
FULL OUTER JOIN store_returns_agg sra ON COALESCE(ssa.ca_state, csa.ca_state) = sra.ca_state
FULL OUTER JOIN web_returns_agg   wra ON COALESCE(ssa.ca_state, csa.ca_state, sra.ca_state) = wra.ca_state
ORDER BY net_profit DESC
LIMIT 20

WITH
  sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
  ),
  returns_without_sales AS (
    SELECT sr_customer_sk
    FROM store_returns
    EXCEPT
    SELECT cs_bill_customer_sk
    FROM catalog_sales
  ),
  joined AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_store_sk,
      sr.sr_customer_sk,
      sr.sr_return_amt_inc_tax,
      cs.cs_net_profit,
      s.s_store_name,
      d_ret.d_year AS return_year,
      ca.ca_city,
      cs.cs_quantity,
      inv.inv_quantity_on_hand,
      (
        SELECT SUM(sr2.sr_return_amt_inc_tax)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = sr.sr_store_sk
      ) AS store_total_return_amt
    FROM store_returns sr
    JOIN date_dim d_ret
      ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_sales cs
      ON cs.cs_bill_customer_sk = c.c_customer_sk
     AND cs.cs_sold_date_sk = d_ret.d_date_sk
    JOIN sampled_inventory inv
      ON inv.inv_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND s.s_state = 'CA'
      AND ca.ca_city = 'Lincoln'
      AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
          AND cs2.cs_quantity > 10
      )
  )
SELECT
  s_store_name,
  return_year,
  ca_city,
  cs_quantity,
  inv_quantity_on_hand,
  sr_return_amt_inc_tax,
  cs_net_profit,
  store_total_return_amt,
  RANK() OVER (PARTITION BY s_store_name ORDER BY cs_net_profit DESC) AS profit_rank,
  DENSE_RANK() OVER (ORDER BY sr_return_amt_inc_tax DESC) AS return_amount_dense_rank
FROM joined
WHERE sr_customer_sk IN (SELECT sr_customer_sk FROM returns_without_sales)
ORDER BY profit_rank
LIMIT 100

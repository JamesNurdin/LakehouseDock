WITH ss_agg AS (
  SELECT ss_addr_sk AS address_sk,
         SUM(ss_net_profit) AS store_profit,
         SUM(ss_quantity) AS store_qty,
         COUNT(*) AS store_cnt
  FROM store_sales
  WHERE ss_quantity > 5
  GROUP BY ss_addr_sk
),
cr_agg AS (
  SELECT cr_refunded_addr_sk AS address_sk,
         SUM(cr_net_loss) AS return_loss,
         SUM(cr_return_quantity) AS return_qty,
         COUNT(*) AS return_cnt
  FROM catalog_returns
  WHERE cr_fee > 30
  GROUP BY cr_refunded_addr_sk
)
SELECT ca.ca_state,
       SUM(ss.store_profit) AS total_store_profit,
       SUM(cr.return_loss) AS total_return_loss,
       SUM(ss.store_profit) - SUM(cr.return_loss) AS net_margin,
       SUM(ss.store_qty) AS total_store_qty,
       SUM(cr.return_qty) AS total_return_qty,
       COUNT(DISTINCT ss.address_sk) AS distinct_store_addresses,
       COUNT(DISTINCT cr.address_sk) AS distinct_return_addresses,
       RANK() OVER (ORDER BY (SUM(ss.store_profit) - SUM(cr.return_loss)) DESC) AS profit_rank
FROM ss_agg ss
JOIN cr_agg cr ON ss.address_sk = cr.address_sk
JOIN customer_address ca ON ca.ca_address_sk = ss.address_sk
WHERE ca.ca_country = 'United States'
GROUP BY ca.ca_state
HAVING SUM(ss.store_profit) - SUM(cr.return_loss) > 10000
ORDER BY net_margin DESC
LIMIT 50

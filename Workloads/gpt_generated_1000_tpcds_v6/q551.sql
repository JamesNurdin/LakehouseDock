SELECT sr_store_sk,
       sum(sr_refunded_cash) AS total_refunded,
       sum(sr_net_loss) AS total_net_loss,
       count(*) AS return_count
FROM tpcds.store_returns
WHERE sr_addr_sk = 1908137
  AND sr_refunded_cash > 100
GROUP BY sr_store_sk
HAVING sum(sr_refunded_cash) > 500
ORDER BY total_refunded DESC
LIMIT 100

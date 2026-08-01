SELECT
    store.s_store_id,
    store.s_store_name,
    SUM(store_returns.sr_return_amt) AS total_return_amt,
    SUM(store_returns.sr_refunded_cash) AS total_refunded_cash
FROM tpcds.store AS store
JOIN tpcds.store_returns AS store_returns
  ON store_returns.sr_store_sk = store.s_store_sk
WHERE store.s_zip = '61933'
  AND store_returns.sr_store_credit > 100
GROUP BY store.s_store_id, store.s_store_name
ORDER BY total_return_amt DESC
LIMIT 100

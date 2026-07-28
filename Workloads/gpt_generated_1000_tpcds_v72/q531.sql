SELECT DISTINCT sr_store_sk, sr_returned_date_sk
FROM tpcds.store_returns
WHERE sr_return_ship_cost > 500
  AND sr_refunded_cash < 100

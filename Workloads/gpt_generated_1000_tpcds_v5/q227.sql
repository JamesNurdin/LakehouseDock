SELECT DISTINCT sr.sr_ticket_number,
                sr.sr_refunded_cash,
                sr.sr_return_quantity
FROM tpcds.store_returns AS sr
WHERE sr.sr_refunded_cash > 50.00
  AND sr.sr_return_quantity >= 20
LIMIT 100

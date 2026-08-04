SELECT sr_ticket_number,
       SUM(sr_refunded_cash) AS total_refunded
FROM   store_returns
WHERE  sr_ticket_number IN (2517572, 2517574)
  AND  sr_refunded_cash > 100.00
GROUP BY sr_ticket_number
HAVING SUM(sr_refunded_cash) > 200.00
ORDER BY total_refunded DESC

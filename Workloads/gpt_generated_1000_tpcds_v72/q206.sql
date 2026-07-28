SELECT
    i.i_item_id,
    i.i_item_desc,
    'store' AS channel,
    COUNT(sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE i.i_current_price BETWEEN 20 AND 200
  AND hd.hd_buy_potential = '501-1000'
GROUP BY i.i_item_id, i.i_item_desc
HAVING COUNT(sr.sr_ticket_number) >= 50
   AND AVG(sr.sr_return_amt) > 20

UNION ALL

SELECT
    i.i_item_id,
    i.i_item_desc,
    'web' AS channel,
    COUNT(wr.wr_order_number) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_amt) AS avg_return_amount
FROM web_returns wr
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE i.i_current_price BETWEEN 20 AND 200
  AND hd.hd_buy_potential = '501-1000'
GROUP BY i.i_item_id, i.i_item_desc
HAVING COUNT(wr.wr_order_number) >= 50
   AND AVG(wr.wr_return_amt) > 20

ORDER BY total_return_amount DESC
LIMIT 100

WITH wr_avg AS (
    SELECT wr.wr_item_sk,
           AVG(wr.wr_return_amt) AS avg_return_amt
    FROM web_returns wr
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE t_wr.t_hour BETWEEN 9 AND 18
    GROUP BY wr.wr_item_sk
)
SELECT DISTINCT
    i.i_item_id,
    i.i_product_name,
    ca1.ca_city,
    ca1.ca_state,
    cd1.cd_gender,
    hd1.hd_buy_potential,
    r1.r_reason_desc,
    sr.sr_return_amt,
    ws.ws_net_profit,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY sr.sr_return_amt DESC) AS return_rank,
    CASE
        WHEN ws.ws_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_flag,
    COALESCE(wr_avg.avg_return_amt, 0) AS avg_web_return_amt
FROM store_returns sr
JOIN time_dim t1 ON sr.sr_return_time_sk = t1.t_time_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd1 ON sr.sr_cdemo_sk = cd1.cd_demo_sk
JOIN household_demographics hd1 ON sr.sr_hdemo_sk = hd1.hd_demo_sk
JOIN customer_address ca1 ON sr.sr_addr_sk = ca1.ca_address_sk
JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
JOIN time_dim t3 ON wr.wr_returned_time_sk = t3.t_time_sk
JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
LEFT JOIN wr_avg ON wr_avg.wr_item_sk = i.i_item_sk
WHERE i.i_current_price > 50
  AND sr.sr_return_amt > 100
  AND r1.r_reason_desc LIKE '%size%'
  AND hd1.hd_buy_potential = '501-1000'
  AND ca1.ca_state = 'CA'
  AND t1.t_hour BETWEEN 9 AND 17
ORDER BY sr.sr_return_amt DESC, i.i_item_id
LIMIT 100

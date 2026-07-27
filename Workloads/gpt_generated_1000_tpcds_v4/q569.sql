WITH wr_filtered AS (
    SELECT wr_item_sk,
           COUNT(*) AS web_ret_cnt,
           SUM(wr_return_amt) AS web_ret_total
    FROM web_returns
    WHERE wr_return_ship_cost < 500
      AND wr_return_tax > 5
      AND wr_account_credit BETWEEN 1 AND 10
      AND wr_return_quantity >= 1
      AND wr_reason_sk IN (6, 12, 15)
    GROUP BY wr_item_sk
)
SELECT
    s.s_store_name,
    i.i_brand,
    i.i_category,
    cd.cd_gender,
    ca.ca_county,
    r.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    SUM(sr.sr_return_amt) AS store_return_amt_total,
    SUM(CASE WHEN r.r_reason_desc LIKE 'Did not%' THEN sr.sr_return_amt ELSE 0 END) AS did_not_reason_amt,
    wrf.web_ret_cnt,
    wrf.web_ret_total,
    (SUM(sr.sr_return_amt) / NULLIF(COUNT(DISTINCT sr.sr_ticket_number), 0)) AS avg_return_amt_per_ticket
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
LEFT JOIN wr_filtered wrf ON wrf.wr_item_sk = i.i_item_sk
WHERE i.i_current_price BETWEEN 10 AND 100
  AND s.s_state = 'CA'
  AND ca.ca_county = 'Madison County'
  AND cd.cd_gender = 'F'
  AND r.r_reason_desc NOT LIKE '%job%'
  AND EXISTS (
      SELECT 1 FROM web_returns wr2
      WHERE wr2.wr_item_sk = i.i_item_sk
        AND wr2.wr_return_amt > 200
  )
GROUP BY
    s.s_store_name,
    i.i_brand,
    i.i_category,
    cd.cd_gender,
    ca.ca_county,
    r.r_reason_desc,
    wrf.web_ret_cnt,
    wrf.web_ret_total
ORDER BY store_return_amt_total DESC
LIMIT 100

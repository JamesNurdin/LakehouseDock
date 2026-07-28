WITH sr_agg AS (
  SELECT
    sr.sr_customer_sk,
    ca_s.ca_state,
    hd_s.hd_buy_potential,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag
  FROM store_returns sr
  JOIN customer_address ca_s
    ON sr.sr_addr_sk = ca_s.ca_address_sk
  JOIN customer_demographics cd_s
    ON sr.sr_cdemo_sk = cd_s.cd_demo_sk
  JOIN household_demographics hd_s
    ON sr.sr_hdemo_sk = hd_s.hd_demo_sk
  WHERE sr.sr_return_amt > 50
    AND cd_s.cd_gender = 'M'
    AND ca_s.ca_gmt_offset = -5.00
    AND hd_s.hd_vehicle_count > 1
  GROUP BY sr.sr_customer_sk,
    ca_s.ca_state,
    hd_s.hd_buy_potential,
    cd_s.cd_gender,
    ca_s.ca_gmt_offset
),
wr_joined AS (
  SELECT
    wr.wr_returning_customer_sk,
    ca_w.ca_state AS returning_state,
    wp.wp_rec_start_date,
    SUM(wr.wr_return_amt) AS wr_total_return_amt,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
  FROM web_returns wr
  JOIN customer_address ca_w
    ON wr.wr_returning_addr_sk = ca_w.ca_address_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_rec_start_date BETWEEN DATE '1999-09-04' AND DATE '2000-09-03'
    AND wr.wr_return_amt > 20
    AND ca_w.ca_gmt_offset = -7.00
  GROUP BY wr.wr_returning_customer_sk,
    ca_w.ca_state,
    wp.wp_rec_start_date
)
SELECT
  sra.sr_customer_sk,
  sra.ca_state,
  sra.hd_buy_potential,
  sra.total_return_amt,
  sra.total_net_loss,
  sra.loss_flag,
  sra.return_cnt,
  wrj.wr_total_return_amt,
  wrj.distinct_orders,
  AVG(sra.total_return_amt) OVER (PARTITION BY sra.ca_state) AS avg_state_return_amt,
  RANK() OVER (ORDER BY sra.total_return_amt DESC) AS return_amount_rank,
  (SELECT AVG(sr_return_amt) FROM store_returns) AS overall_avg_return_amt
FROM sr_agg sra
LEFT JOIN wr_joined wrj
  ON sra.sr_customer_sk = wrj.wr_returning_customer_sk
WHERE sra.return_cnt > 1
ORDER BY sra.total_return_amt DESC
LIMIT 100

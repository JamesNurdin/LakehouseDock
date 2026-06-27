SELECT
    ca.ca_state,
    d.d_year,
    hd.hd_income_band_sk,
    i.i_category,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
FROM web_returns wr
JOIN date_dim d
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i
  ON wr.wr_item_sk = i.i_item_sk
JOIN customer_address ca
  ON wr.wr_returning_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
WHERE d.d_date >= DATE '2022-01-01'
  AND d.d_date < DATE '2023-01-01'
GROUP BY ca.ca_state, d.d_year, hd.hd_income_band_sk, i.i_category
ORDER BY total_net_loss DESC
LIMIT 20

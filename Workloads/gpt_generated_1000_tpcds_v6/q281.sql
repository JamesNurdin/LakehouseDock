WITH base AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    i.i_item_sk,
    i.i_category,
    i.i_current_price,
    ca.ca_address_sk,
    ca.ca_state AS ca_state,
    ca.ca_gmt_offset,
    cd1.cd_gender,
    cd1.cd_marital_status,
    hd1.hd_buy_potential,
    hd1.hd_vehicle_count,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_fee,
    sr.sr_net_loss AS store_net_loss,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_fee,
    wr.wr_net_loss AS web_net_loss,
    wp.wp_type,
    CASE WHEN sr.sr_net_loss > 500 THEN 'HIGH' ELSE 'LOW' END AS store_loss_category,
    CASE WHEN wr.wr_net_loss > 500 THEN 'HIGH' ELSE 'LOW' END AS web_loss_category
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd1 ON sr.sr_cdemo_sk = cd1.cd_demo_sk
  JOIN household_demographics hd1 ON sr.sr_hdemo_sk = hd1.hd_demo_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN customer_demographics cd2 ON wr.wr_refunded_cdemo_sk = cd2.cd_demo_sk
  JOIN household_demographics hd2 ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
  WHERE s.s_state = 'CA'
    AND i.i_category = 'Electronics'
    AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
    AND hd1.hd_vehicle_count >= 1
    AND cd1.cd_gender = 'M'
    AND sr.sr_fee > 20
    AND wr.wr_return_amt > 50
),
agg AS (
  SELECT
    s_store_sk,
    s_store_name,
    s_state,
    i_category,
    SUM(store_net_loss) AS total_store_loss,
    SUM(web_net_loss) AS total_web_loss,
    SUM(store_net_loss + web_net_loss) AS total_combined_loss,
    COUNT(*) AS txn_count
  FROM base
  GROUP BY s_store_sk, s_store_name, s_state, i_category
)
SELECT
  s_store_sk,
  s_store_name,
  s_state,
  i_category,
  total_store_loss,
  total_web_loss,
  total_combined_loss,
  txn_count,
  ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_combined_loss DESC) AS loss_rank
FROM agg
ORDER BY s_state, loss_rank
LIMIT 100

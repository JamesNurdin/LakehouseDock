WITH
  store_agg AS (
    SELECT
      ca.ca_state,
      MIN(ca.ca_zip) AS sample_zip,
      SUM(ss.ss_net_profit) AS total_store_profit,
      COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2002
      AND regexp_like(ca.ca_address_id, '^AAAAAAA[AB].*AAAA$')
      AND ca.ca_city LIKE '%Town%'
      AND hd.hd_vehicle_count >= 2
    GROUP BY ca.ca_state
  ),
  web_agg AS (
    SELECT
      ca.ca_state,
      SUM(wr.wr_net_loss) AS total_web_loss,
      COUNT(*) AS web_ret_txn_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2002
      AND regexp_like(ca.ca_address_id, '^AAAAAAA[AB].*AAAA$')
      AND ca.ca_city LIKE '%Town%'
      AND hd.hd_vehicle_count >= 2
    GROUP BY ca.ca_state
  )
SELECT
  sa.ca_state,
  CONCAT('State_', sa.ca_state) AS state_label,
  sa.total_store_profit,
  wa.total_web_loss,
  CASE
    WHEN sa.total_store_profit > 0 AND wa.total_web_loss < 0 THEN 'Profit vs Loss'
    WHEN sa.total_store_profit > 0 THEN 'Profit Only'
    WHEN wa.total_web_loss < 0 THEN 'Loss Only'
    ELSE 'Neutral'
  END AS profit_loss_category,
  (sa.total_store_profit + COALESCE(wa.total_web_loss, 0)) AS net_combined,
  REGEXP_EXTRACT(sa.sample_zip, '^([0-9]{3})', 1) AS zip_prefix,
  CONCAT('ZIP_', REGEXP_EXTRACT(sa.sample_zip, '^([0-9]{3})', 1)) AS zip_prefix_label
FROM store_agg sa
LEFT JOIN web_agg wa ON sa.ca_state = wa.ca_state
WHERE sa.total_store_profit > (
        SELECT AVG(total_store_profit)
        FROM store_agg
      )
ORDER BY net_combined DESC
LIMIT 100

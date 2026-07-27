WITH
  store_ret AS (
    SELECT
      dt.d_year AS return_year,
      it.i_brand AS brand,
      SUM(sr.sr_net_loss) AS total_net_loss,
      CAST('store' AS VARCHAR) AS channel
    FROM store_returns sr
    JOIN date_dim dt ON sr.sr_returned_date_sk = dt.d_date_sk
    JOIN item it ON sr.sr_item_sk = it.i_item_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    WHERE dt.d_year = 2001
      AND it.i_brand_id = 1001001
    GROUP BY dt.d_year, it.i_brand
  ),
  web_ret AS (
    SELECT
      dt.d_year AS return_year,
      it.i_brand AS brand,
      SUM(wr.wr_net_loss) AS total_net_loss,
      CAST('web' AS VARCHAR) AS channel
    FROM web_returns wr
    JOIN date_dim dt ON wr.wr_returned_date_sk = dt.d_date_sk
    JOIN item it ON wr.wr_item_sk = it.i_item_sk
    WHERE dt.d_year = 2001
      AND it.i_brand_id = 1001001
    GROUP BY dt.d_year, it.i_brand
  )
SELECT * FROM store_ret
UNION ALL
SELECT * FROM web_ret
ORDER BY total_net_loss DESC
LIMIT 100

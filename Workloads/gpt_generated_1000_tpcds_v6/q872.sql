WITH
  base_sales AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_ticket_number,
      ss.ss_net_paid,
      ss.ss_net_profit,
      d_sales.d_year,
      i_sales.i_category,
      s_store.s_store_id,
      s_store.s_store_name,
      s_store.s_state
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i_sales ON ss.ss_item_sk = i_sales.i_item_sk
    JOIN store s_store ON ss.ss_store_sk = s_store.s_store_sk
    WHERE d_sales.d_year = 2001
  ),
  returns_data AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_item_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      d_ret.d_year AS ret_year,
      i_ret.i_category AS ret_category,
      s_ret.s_store_id
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i_ret ON sr.sr_item_sk = i_ret.i_item_sk
    JOIN store s_ret ON sr.sr_store_sk = s_ret.s_store_sk
    WHERE d_ret.d_year = 2001
  ),
  web_activity AS (
    SELECT
      wr.wr_item_sk,
      wr.wr_return_amt,
      wr.wr_net_loss,
      wp.wp_type,
      d_web.d_year AS web_year,
      i_web.i_category AS web_category
    FROM web_returns wr
    JOIN date_dim d_web ON wr.wr_returned_date_sk = d_web.d_date_sk
    JOIN item i_web ON wr.wr_item_sk = i_web.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d_web.d_year = 2001
  )
SELECT
  bs.s_store_id,
  bs.s_store_name,
  bs.s_state,
  bs.i_category,
  SUM(bs.ss_net_profit) AS total_net_profit,
  COALESCE(SUM(rd.sr_net_loss), 0) AS total_store_return_loss,
  COALESCE(SUM(wa.wr_net_loss), 0) AS total_web_return_loss,
  ROW_NUMBER() OVER (PARTITION BY bs.s_store_id ORDER BY SUM(bs.ss_net_profit) DESC) AS profit_rank
FROM base_sales bs
LEFT JOIN returns_data rd
  ON bs.ss_ticket_number = rd.sr_ticket_number
  AND bs.ss_item_sk = rd.sr_item_sk
LEFT JOIN web_activity wa
  ON bs.ss_item_sk = wa.wr_item_sk
WHERE EXISTS (
  SELECT 1
  FROM web_activity wa2
  WHERE wa2.wr_item_sk = bs.ss_item_sk
    AND wa2.wr_return_amt > 100
    AND wa2.web_year = 2001
)
GROUP BY
  bs.s_store_id,
  bs.s_store_name,
  bs.s_state,
  bs.i_category
ORDER BY total_net_profit DESC
LIMIT 100

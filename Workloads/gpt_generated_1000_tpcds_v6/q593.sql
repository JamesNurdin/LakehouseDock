WITH filtered AS (
  SELECT
    i.i_item_id,
    i.i_brand,
    i.i_category,
    d.d_year,
    ca.ca_state,
    ss.ss_quantity AS ss_quantity,
    ws.ws_quantity AS ws_quantity,
    ss.ss_net_profit AS ss_net_profit,
    ws.ws_net_profit AS ws_net_profit
  FROM store_sales ss
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim d_wp
    ON wp.wp_creation_date_sk = d_wp.d_date_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#23'
    AND ca.ca_state = 'TX'
    AND ws.ws_net_profit > 0
    AND hd.hd_income_band_sk BETWEEN 3 AND 5
    AND EXISTS (
      SELECT 1
      FROM catalog_returns cr
      WHERE cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
        AND cr.cr_refunded_addr_sk = ss.ss_addr_sk
    )
),
agg AS (
  SELECT
    i_item_id,
    i_brand,
    i_category,
    d_year,
    ca_state,
    SUM(ss_quantity) AS total_store_qty,
    SUM(ws_quantity) AS total_web_qty,
    SUM(ss_net_profit + ws_net_profit) AS total_net_profit
  FROM filtered
  GROUP BY i_item_id, i_brand, i_category, d_year, ca_state
)
SELECT
  i_item_id,
  i_brand,
  i_category,
  d_year,
  ca_state,
  total_store_qty,
  total_web_qty,
  total_net_profit,
  RANK() OVER (PARTITION BY i_brand ORDER BY total_net_profit DESC) AS brand_profit_rank
FROM agg
ORDER BY total_net_profit DESC, i_item_id
LIMIT 100

WITH
item_colors AS (
   SELECT i_item_sk, color
   FROM (
        SELECT i_item_sk, array_agg(i_color) AS colors
        FROM item
        GROUP BY i_item_sk
   ) agg
   CROSS JOIN UNNEST(colors) AS t(color)
),
base_join AS (
   SELECT
      cr.cr_returned_date_sk,
      d_cr.d_year,
      i.i_item_sk,
      i.i_manufact,
      sm.sm_type AS return_ship_mode,
      p.p_promo_name,
      ws.ws_quantity,
      ws.ws_net_profit,
      s.s_store_name,
      d_ws_sold.d_quarter_name AS sold_quarter,
      c.color
   FROM catalog_returns cr
   JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN store s ON s.s_closed_date_sk = d_cr.d_date_sk
   LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
   JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
   JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
   JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
   JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
   JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
   JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
   JOIN item_colors c ON c.i_item_sk = i.i_item_sk
   WHERE EXISTS (
       SELECT 1 FROM web_returns wr2
       WHERE wr2.wr_order_number = ws.ws_order_number
         AND wr2.wr_return_amt > 0
   )
),
agg_year_manufact AS (
   SELECT
      d_year,
      i_manufact,
      SUM(ws_quantity) AS total_quantity,
      SUM(ws_net_profit) AS total_profit
   FROM base_join
   GROUP BY d_year, i_manufact
),
agg_quarter_ship AS (
   SELECT
      sold_quarter,
      return_ship_mode,
      COUNT(DISTINCT i_item_sk) AS distinct_items,
      SUM(qty) AS qty_sum
   FROM (
       SELECT sold_quarter, return_ship_mode, i_item_sk, ws_quantity AS qty
       FROM base_join
   ) sub
   GROUP BY sold_quarter, return_ship_mode
),
union_all AS (
   SELECT CAST(d_year AS varchar) AS period,
          i_manufact AS group_key,
          total_quantity,
          total_profit
   FROM agg_year_manufact
   UNION DISTINCT
   SELECT sold_quarter AS period,
          return_ship_mode AS group_key,
          qty_sum AS total_quantity,
          CAST(NULL AS decimal(7,2)) AS total_profit
   FROM agg_quarter_ship
),
final_set AS (
   SELECT u.period, u.group_key, u.total_quantity, u.total_profit
   FROM union_all u
   EXCEPT
   SELECT CAST(d_year AS varchar) AS period,
          i_manufact AS group_key,
          0 AS total_quantity,
          0 AS total_profit
   FROM agg_year_manufact
   WHERE total_profit = 0
)
SELECT
   f.period,
   f.group_key,
   f.total_quantity,
   f.total_profit,
   s.s_store_name
FROM final_set f
FULL OUTER JOIN store s ON s.s_store_name = f.group_key
ORDER BY f.period DESC, f.total_quantity DESC
LIMIT 100

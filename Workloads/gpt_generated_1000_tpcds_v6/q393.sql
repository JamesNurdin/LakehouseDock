WITH base AS (
  SELECT
    s.s_store_name               AS s_store_name,
    s.s_state                    AS s_state,
    i.i_item_id                  AS i_item_id,
    i.i_brand                    AS i_brand,
    td.t_hour                    AS t_hour,
    c.c_customer_id              AS c_customer_id,
    ss.ss_net_paid               AS ss_net_paid,
    ws.ws_net_paid_inc_ship      AS ws_net_paid_inc_ship,
    p.p_cost                     AS p_cost,
    ib.ib_upper_bound            AS ib_upper_bound,
    (
      SELECT SUM(sr2.sr_return_quantity)
      FROM store_returns sr2
      WHERE sr2.sr_item_sk = i.i_item_sk
    )                            AS total_store_return_qty
  FROM store_sales ss
  JOIN time_dim td               ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store s                   ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store_returns sr          ON ss.ss_ticket_number = sr.sr_ticket_number
                                 AND ss.ss_item_sk = sr.sr_item_sk
  JOIN web_sales ws              ON td.t_time_sk = ws.ws_sold_time_sk
                                 AND ws.ws_item_sk = i.i_item_sk
                                 AND ws.ws_bill_customer_sk = c.c_customer_sk
                                 AND ws.ws_ship_customer_sk = c.c_customer_sk
                                 AND ws.ws_promo_sk = p.p_promo_sk
  JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite            ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN warehouse w               ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_returns wr            ON ws.ws_order_number = wr.wr_order_number
                                 AND ws.ws_item_sk = wr.wr_item_sk
                                 AND wr.wr_item_sk = i.i_item_sk
  WHERE td.t_hour = 14
    AND i.i_brand = 'Brand#23'
    AND ib.ib_upper_bound = 100000
    AND p.p_discount_active = 'Y'
    AND EXISTS (
          SELECT 1
          FROM store_returns sr_check
          WHERE sr_check.sr_item_sk = i.i_item_sk
            AND sr_check.sr_return_quantity > 0
        )
)
SELECT
  s_store_name,
  s_state,
  i_item_id,
  i_brand,
  t_hour,
  COUNT(DISTINCT c_customer_id)                AS unique_customers,
  SUM(ss_net_paid)                             AS total_store_sales,
  SUM(ws_net_paid_inc_ship)                    AS total_web_sales,
  AVG(p_cost)                                  AS avg_promo_cost,
  MIN(ib_upper_bound)                          AS min_income_upper,
  MAX(ib_upper_bound)                          AS max_income_upper,
  SUM(total_store_return_qty)                  AS total_store_returns
FROM base
GROUP BY
  s_store_name,
  s_state,
  i_item_id,
  i_brand,
  t_hour
ORDER BY total_store_sales DESC
LIMIT 100

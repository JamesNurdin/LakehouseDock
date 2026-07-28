/*
  Goal: Combine store and web sales with promotions, inventory, returns, and demographic information for the year 2002.
  The query aggregates net profit from store and web channels, net loss from returns, and inventory on hand per store,
  promotion, and month. It also filters to promotions that have at least one associated web page and to male customers.
*/
WITH
  /* Store‑sales aggregation per store, promotion and month */
  store_sales_agg AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      p.p_promo_sk,
      p.p_promo_name,
      ds.d_year,
      ds.d_month_seq,
      SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk    = s.s_store_sk
    JOIN promotion p           ON ss.ss_promo_sk    = p.p_promo_sk
    JOIN date_dim ds           ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN time_dim ts           ON ss.ss_sold_time_sk = ts.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ds.d_year = 2002
      AND ts.t_hour BETWEEN 9 AND 17           -- business hours
      AND cd.cd_gender = 'M'                    -- male customers only
    GROUP BY
      s.s_store_sk,
      s.s_store_name,
      p.p_promo_sk,
      p.p_promo_name,
      ds.d_year,
      ds.d_month_seq
  ),

  /* Web‑sales aggregation per promotion and month */
  web_sales_agg AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_name,
      dw.d_year,
      dw.d_month_seq,
      SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN promotion p           ON ws.ws_promo_sk    = p.p_promo_sk
    JOIN date_dim dw           ON ws.ws_sold_date_sk = dw.d_date_sk
    JOIN time_dim tw           ON ws.ws_sold_time_sk = tw.t_time_sk
    WHERE dw.d_year = 2002
      AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
          )
    GROUP BY
      p.p_promo_sk,
      p.p_promo_name,
      dw.d_year,
      dw.d_month_seq
  ),

  /* Returns aggregation per month */
  returns_agg AS (
    SELECT
      dr.d_year,
      dr.d_month_seq,
      SUM(wr.wr_net_loss) AS returns_net_loss
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN time_dim tr ON wr.wr_returned_time_sk = tr.t_time_sk
    WHERE dr.d_year = 2002
    GROUP BY dr.d_year, dr.d_month_seq
  ),

  /* Inventory aggregation per month */
  inventory_agg AS (
    SELECT
      di.d_year,
      di.d_month_seq,
      SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM inventory i
    JOIN date_dim di ON i.inv_date_sk = di.d_date_sk
    WHERE di.d_year = 2002
    GROUP BY di.d_year, di.d_month_seq
  )

SELECT
  ss.s_store_name,
  ss.p_promo_name,
  ss.d_year,
  ss.d_month_seq,
  ss.store_net_profit,
  COALESCE(ws.web_net_profit, 0)      AS web_net_profit,
  COALESCE(r.returns_net_loss, 0)    AS returns_net_loss,
  COALESCE(inv.total_inventory, 0)   AS total_inventory
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
  ON ss.p_promo_sk = ws.p_promo_sk
 AND ss.d_year    = ws.d_year
 AND ss.d_month_seq = ws.d_month_seq
LEFT JOIN returns_agg r
  ON ss.d_year = r.d_year
 AND ss.d_month_seq = r.d_month_seq
LEFT JOIN inventory_agg inv
  ON ss.d_year = inv.d_year
 AND ss.d_month_seq = inv.d_month_seq
ORDER BY ss.store_net_profit DESC, ss.d_year, ss.d_month_seq
LIMIT 100

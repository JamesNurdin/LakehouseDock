WITH
  catalog_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      p.p_channel_tv,
      SUM(cs.cs_net_profit)          AS catalog_net_profit,
      COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN date_dim d      ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN time_dim t      ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN item i          ON cs.cs_item_sk        = i.i_item_sk
    JOIN promotion p     ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w     ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND t.t_shift = 'first'
    GROUP BY ROLLUP (d.d_year, i.i_category, p.p_channel_tv)
  ),
  web_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      p.p_channel_tv,
      SUM(ws.ws_net_profit)          AS web_net_profit,
      COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN date_dim d      ON ws.ws_sold_date_sk   = d.d_date_sk
    JOIN time_dim t      ON ws.ws_sold_time_sk   = t.t_time_sk
    JOIN item i          ON ws.ws_item_sk        = i.i_item_sk
    JOIN promotion p     ON ws.ws_promo_sk       = p.p_promo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w     ON ws.ws_warehouse_sk   = w.w_warehouse_sk
    JOIN web_page wp     ON ws.ws_web_page_sk    = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND t.t_shift = 'first'
    GROUP BY ROLLUP (d.d_year, i.i_category, p.p_channel_tv)
  ),
  store_return_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(sr.sr_net_loss) AS store_return_loss,
      COUNT(*)            AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim d      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t      ON sr.sr_return_time_sk   = t.t_time_sk
    JOIN item i          ON sr.sr_item_sk          = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND t.t_shift = 'first'
    GROUP BY ROLLUP (d.d_year, i.i_category)
  ),
  web_return_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(wr.wr_net_loss) AS web_return_loss,
      COUNT(*)            AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t      ON wr.wr_returned_time_sk   = t.t_time_sk
    JOIN item i          ON wr.wr_item_sk            = i.i_item_sk
    JOIN web_page wp     ON wr.wr_web_page_sk        = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND t.t_shift = 'first'
    GROUP BY ROLLUP (d.d_year, i.i_category)
  )
SELECT
  COALESCE(c.d_year, w.d_year, sr.d_year, wr.d_year)          AS year,
  COALESCE(c.i_category, w.i_category, sr.i_category, wr.i_category) AS category,
  c.p_channel_tv,
  c.catalog_net_profit,
  c.catalog_orders,
  w.web_net_profit,
  w.web_orders,
  sr.store_return_loss,
  sr.store_return_cnt,
  wr.web_return_loss,
  wr.web_return_cnt
FROM catalog_agg c
FULL OUTER JOIN web_agg w
  ON c.d_year = w.d_year
 AND c.i_category = w.i_category
 AND c.p_channel_tv = w.p_channel_tv
FULL OUTER JOIN store_return_agg sr
  ON COALESCE(c.d_year, w.d_year) = sr.d_year
 AND COALESCE(c.i_category, w.i_category) = sr.i_category
FULL OUTER JOIN web_return_agg wr
  ON COALESCE(c.d_year, w.d_year, sr.d_year) = wr.d_year
 AND COALESCE(c.i_category, w.i_category, sr.i_category) = wr.i_category
ORDER BY year DESC, category ASC, c.p_channel_tv

WITH
  sales_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      d.d_year,
      SUM(ss.ss_net_profit) AS total_sales_profit,
      SUM(ss.ss_net_paid_inc_tax) AS total_sales_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND ss.ss_net_paid_inc_tax > 1000
      AND hd.hd_buy_potential = 'HIGH'
    GROUP BY c.c_customer_sk, c.c_customer_id, d.d_year
  ),
  returns_agg AS (
    SELECT
      c.c_customer_sk,
      SUM(sr.sr_net_loss) AS total_store_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
    GROUP BY c.c_customer_sk
  ),
  catalog_agg AS (
    SELECT
      c.c_customer_sk,
      SUM(cr.cr_net_loss) AS total_catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
    GROUP BY c.c_customer_sk
  ),
  web_page_agg AS (
    SELECT
      c.c_customer_sk,
      COUNT(wp.wp_web_page_id) AS page_view_cnt,
      SUM(wp.wp_char_count) AS total_char_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND wp.wp_type = 'article'
    GROUP BY c.c_customer_sk
  ),
  inventory_year_agg AS (
    SELECT
      d.d_year,
      SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND inv.inv_quantity_on_hand > 0
    GROUP BY d.d_year
  )
SELECT
  s.c_customer_id,
  s.d_year,
  s.total_sales_profit,
  COALESCE(r.total_store_return_loss, 0) AS total_store_return_loss,
  COALESCE(ca.total_catalog_return_loss, 0) AS total_catalog_return_loss,
  COALESCE(w.page_view_cnt, 0) AS page_view_cnt,
  COALESCE(iy.total_qty_on_hand, 0) AS total_qty_on_hand,
  (s.total_sales_profit
   - COALESCE(r.total_store_return_loss, 0)
   - COALESCE(ca.total_catalog_return_loss, 0)) AS net_gain,
  RANK() OVER (ORDER BY (s.total_sales_profit
                         - COALESCE(r.total_store_return_loss, 0)
                         - COALESCE(ca.total_catalog_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r ON s.c_customer_sk = r.c_customer_sk
LEFT JOIN catalog_agg ca ON s.c_customer_sk = ca.c_customer_sk
LEFT JOIN web_page_agg w ON s.c_customer_sk = w.c_customer_sk
LEFT JOIN inventory_year_agg iy ON s.d_year = iy.d_year
ORDER BY profit_rank
LIMIT 100

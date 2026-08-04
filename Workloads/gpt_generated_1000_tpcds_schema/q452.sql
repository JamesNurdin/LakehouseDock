WITH
  d_sold AS (SELECT * FROM date_dim),
  d_ret AS (SELECT * FROM date_dim),
  d_wr AS (SELECT * FROM date_dim),
  d_store AS (SELECT * FROM date_dim),
  d_ws AS (SELECT * FROM date_dim),

  sales_base AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_item_sk,
      cs.cs_bill_customer_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_warehouse_sk,
      cs.cs_net_profit,
      cs.cs_order_number,
      d_sold.d_year AS year,
      i.i_item_id,
      i.i_category,
      w.w_warehouse_name,
      c.c_customer_id,
      hd.hd_income_band_sk,
      ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN d_sold d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d_sold.d_year BETWEEN 1999 AND 2001
  ),

  returns_join AS (
    SELECT
      cr.cr_order_number,
      cr.cr_net_loss,
      d_ret.d_year AS return_year
    FROM catalog_returns cr
    JOIN d_ret d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    WHERE cr.cr_net_loss > 0
  ),

  web_ret_agg AS (
    SELECT
      c.c_customer_id,
      d_wr.d_year AS year,
      SUM(wr.wr_net_loss) AS web_return_loss
    FROM web_returns wr
    JOIN d_wr d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d_wr.d_year BETWEEN 1999 AND 2001
    GROUP BY c.c_customer_id, d_wr.d_year
  ),

  store_join AS (
    SELECT s.s_store_id, d_store.d_year AS store_year
    FROM store s
    JOIN d_store d_store ON s.s_closed_date_sk = d_store.d_date_sk
    WHERE d_store.d_year BETWEEN 1999 AND 2001
  ),

  web_site_join AS (
    SELECT ws.web_site_id, d_ws.d_year AS site_year
    FROM web_site ws
    JOIN d_ws d_ws ON ws.web_open_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year BETWEEN 1999 AND 2001
  ),

  sales_agg AS (
    SELECT
      sb.c_customer_id,
      sb.year,
      SUM(sb.cs_net_profit) AS total_profit,
      SUM(COALESCE(rj.cr_net_loss, 0)) AS total_return_loss
    FROM sales_base sb
    LEFT JOIN returns_join rj ON sb.cs_order_number = rj.cr_order_number
    LEFT JOIN store_join sj ON sb.year = sj.store_year
    LEFT JOIN web_site_join wsj ON sb.year = wsj.site_year
    WHERE EXISTS (
      SELECT 1
      FROM catalog_returns cr2
      WHERE cr2.cr_order_number = sb.cs_order_number
        AND cr2.cr_net_loss > 0
    )
    GROUP BY ROLLUP (sb.c_customer_id, sb.year)
  ),

  union_all AS (
    SELECT
      c_customer_id,
      year,
      total_profit,
      total_return_loss,
      0.0 AS web_return_loss
    FROM sales_agg
    UNION
    SELECT
      c_customer_id,
      year,
      0.0 AS total_profit,
      0.0 AS total_return_loss,
      web_return_loss
    FROM web_ret_agg
  ),

  distinct_customers AS (
    SELECT DISTINCT c_customer_id FROM union_all
    EXCEPT
    SELECT DISTINCT c_customer_id FROM web_ret_agg WHERE web_return_loss = 0
  )

SELECT
  dc.c_customer_id,
  ua.year,
  SUM(ua.total_profit) AS profit,
  SUM(ua.total_return_loss) AS return_loss,
  SUM(ua.web_return_loss) AS web_return_loss
FROM union_all ua
JOIN distinct_customers dc ON ua.c_customer_id = dc.c_customer_id
GROUP BY ROLLUP (dc.c_customer_id, ua.year)
ORDER BY profit DESC
LIMIT 100

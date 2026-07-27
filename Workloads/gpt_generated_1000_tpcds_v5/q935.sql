WITH
  sales_agg AS (
    SELECT
      d_sold.d_year AS sales_year,
      i.i_category AS item_category,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt
    FROM store_sales ss
    JOIN date_dim d_sold
      ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN call_center cc
      ON cc.cc_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ROLLUP (d_sold.d_year, i.i_category)
  ),
  returns_agg AS (
    SELECT
      d_ret.d_year AS return_year,
      i_ret.i_category AS item_category,
      SUM(wr.wr_return_amt) AS total_return_amount,
      SUM(wr.wr_net_loss) AS total_net_loss,
      COUNT(DISTINCT wr.wr_order_number) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item i_ret
      ON wr.wr_item_sk = i_ret.i_item_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_ref
      ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref
      ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN income_band ib_ref
      ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    GROUP BY CUBE (d_ret.d_year, i_ret.i_category)
  )
SELECT
  COALESCE(s.sales_year, r.return_year) AS year,
  COALESCE(s.item_category, r.item_category) AS category,
  s.total_sales,
  s.total_profit,
  s.order_cnt,
  r.total_return_amount,
  r.total_net_loss,
  r.return_cnt
FROM sales_agg s
FULL OUTER JOIN returns_agg r
  ON s.sales_year = r.return_year
  AND s.item_category = r.item_category
ORDER BY year DESC, category
LIMIT 100

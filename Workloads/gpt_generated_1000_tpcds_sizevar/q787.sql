WITH
  -- average discount per promotion from catalog sales
  avg_discount AS (
    SELECT
      p.p_promo_sk,
      AVG(cs.cs_ext_discount_amt) AS avg_cs_discount
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_sk
  ),
  -- base data joining all selected tables
  base AS (
    SELECT
      i.i_item_id,
      i.i_category,
      d_sold.d_year,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
      avgd.avg_cs_discount,
      -- scalar sub‑query: total store sales for the same item
      (SELECT SUM(ss2.ss_net_paid) FROM store_sales ss2 WHERE ss2.ss_item_sk = i.i_item_sk) AS total_item_store_sales,
      -- placeholder column from cross join
      cross_tbl.const_val
    FROM catalog_sales cs
    /* catalog_sales relationships */
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    /* catalog_returns */
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
    JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    /* web_sales */
    JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number
                     AND ws.ws_item_sk = cs.cs_item_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    /* web_returns */
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                      AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
    JOIN time_dim t_wr_return ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
    JOIN customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
    JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
    JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
    JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    /* store_sales */
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                        AND ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ss_sold ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
    JOIN time_dim t_ss_sold ON ss.ss_sold_time_sk = t_ss_sold.t_time_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    /* income_band via household_demographics */
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    /* left join the avg discount CTE */
    LEFT JOIN avg_discount avgd ON avgd.p_promo_sk = p.p_promo_sk
    /* cross join a tiny derived set */
    CROSS JOIN (VALUES 1) AS cross_tbl(const_val)
    WHERE d_sold.d_year = 2000
      AND i.i_category = 'Sports'
      AND ca_bill.ca_state = 'CA'
      AND t_sold.t_hour BETWEEN 9 AND 17
      AND ib.ib_upper_bound > 50000
  ),
  ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY cs_net_profit DESC) AS rn
    FROM base
  )
SELECT
  i_item_id,
  i_category,
  d_year,
  cs_order_number,
  cs_quantity,
  cs_net_paid,
  cs_net_profit,
  profit_flag,
  avg_cs_discount,
  total_item_store_sales,
  const_val,
  rn
FROM ranked
WHERE rn <= 5
LIMIT 100

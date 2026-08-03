WITH
  sales AS (
    SELECT cs.*
    FROM catalog_sales cs
    WHERE cs.cs_order_number NOT IN (SELECT cr_order_number FROM catalog_returns)
  ),
  sales_lateral AS (
    SELECT
      s.*,
      (SELECT SUM(cs2.cs_ext_sales_price)
       FROM catalog_sales cs2
       WHERE cs2.cs_item_sk = s.cs_item_sk
         AND cs2.cs_sold_date_sk = s.cs_sold_date_sk) AS total_item_sales
    FROM sales s
  ),
  base AS (
    SELECT
      sl.cs_order_number,
      sl.cs_net_profit,
      sl.total_item_sales,
      d_sold.d_year,
      d_ship.d_year AS ship_year,
      ca_bill.ca_city      AS bill_city,
      ca_ship.ca_city      AS ship_city,
      hd_bill.hd_income_band_sk,
      hd_ship.hd_income_band_sk AS ship_income_band,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      cc.cc_name,
      cp.cp_department,
      sm.sm_type,
      st.s_store_name,
      wp.wp_url,
      ws.web_name,
      r.r_reason_desc,
      wr.wr_return_quantity
    FROM sales_lateral sl
    JOIN date_dim d_sold       ON sl.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship       ON sl.cs_ship_date_sk = d_ship.d_date_sk
    JOIN call_center cc        ON sl.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp       ON sl.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm          ON sl.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i                ON sl.cs_item_sk = i.i_item_sk
    JOIN promotion p           ON sl.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON sl.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON sl.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN household_demographics hd_bill ON sl.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON sl.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN store st               ON st.s_closed_date_sk = d_ship.d_date_sk
    JOIN date_dim d_wp_create   ON cp.cp_start_date_sk = d_wp_create.d_date_sk
    JOIN web_page wp            ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    JOIN web_site ws            ON ws.web_open_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = sl.cs_order_number
    LEFT JOIN reason r           ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr    ON wr.wr_item_sk = sl.cs_item_sk
    CROSS JOIN (SELECT 1 AS flag UNION ALL SELECT 2 AS flag) AS cross_vals
    WHERE d_sold.d_year = 2001
  ),
  ranked AS (
    SELECT *,
      ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY cs_net_profit DESC) AS profit_rank
    FROM base
  )
SELECT
  cs_order_number,
  cs_net_profit,
  total_item_sales,
  d_year,
  bill_city,
  ship_city,
  i_category,
  i_brand,
  p_promo_name,
  cc_name,
  cp_department,
  sm_type,
  s_store_name,
  wp_url,
  web_name,
  r_reason_desc,
  wr_return_quantity,
  profit_rank
FROM ranked
WHERE profit_rank <= 5
GROUP BY
  cs_order_number,
  cs_net_profit,
  total_item_sales,
  d_year,
  bill_city,
  ship_city,
  i_category,
  i_brand,
  p_promo_name,
  cc_name,
  cp_department,
  sm_type,
  s_store_name,
  wp_url,
  web_name,
  r_reason_desc,
  wr_return_quantity,
  profit_rank
HAVING SUM(cs_net_profit) > 1000
ORDER BY cs_net_profit DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY

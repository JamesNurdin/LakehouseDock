WITH cs AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cs.cs_bill_customer_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_bill_addr_sk,
    cs.cs_ship_mode_sk,
    cs.cs_warehouse_sk,
    cs.cs_promo_sk,
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_net_profit
  FROM catalog_sales cs
  JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
  JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d1.d_year = 2001
    AND ca.ca_state = 'TX'
    AND sm.sm_type = 'AIR'
    AND w.w_state = 'CA'
    AND p.p_channel_email = 'Y'
),
ss AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_hdemo_sk,
    ss.ss_addr_sk,
    ss.ss_store_sk,
    ss.ss_promo_sk,
    ss.ss_ticket_number,
    ss.ss_ext_sales_price,
    ss.ss_net_profit
  FROM store_sales ss
  JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
  JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
  JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
  JOIN customer c2 ON ss.ss_customer_sk = c2.c_customer_sk
  JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
  JOIN customer_address ca2 ON ss.ss_addr_sk = ca2.ca_address_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
  WHERE d2.d_year = 2001
    AND s.s_state = 'CA'
    AND i2.i_brand = 'Brand#12'
    AND c2.c_preferred_cust_flag = 'Y'
    AND hd2.hd_vehicle_count > 1
),
wr AS (
  SELECT
    wr.wr_returned_date_sk,
    wr.wr_item_sk,
    wr.wr_refunded_customer_sk,
    wr.wr_return_amt,
    wr.wr_net_loss
  FROM web_returns wr
  JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk
  JOIN time_dim t3 ON wr.wr_returned_time_sk = t3.t_time_sk
  JOIN item i3 ON wr.wr_item_sk = i3.i_item_sk
  JOIN customer c3 ON wr.wr_refunded_customer_sk = c3.c_customer_sk
  JOIN household_demographics hd3 ON wr.wr_refunded_hdemo_sk = hd3.hd_demo_sk
  JOIN customer_address ca3 ON wr.wr_refunded_addr_sk = ca3.ca_address_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE d3.d_year = 2001
    AND wp.wp_type = 'content'
    AND i3.i_category = 'Women'
    AND c3.c_birth_country = 'United States'
    AND ca3.ca_county = 'Richland County'
),
order_excl AS (
  SELECT cs_order_number FROM catalog_sales
  EXCEPT
  SELECT ss_ticket_number FROM store_sales
),
base AS (
  SELECT
    COALESCE(cs.cs_item_sk, ss.ss_item_sk)               AS item_sk,
    i.i_brand,
    i.i_category,
    d_year.d_year,
    COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0) AS sales_amount,
    COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) - COALESCE(wr.wr_net_loss, 0) AS profit_amount,
    COALESCE(cs.cs_order_number, ss.ss_ticket_number)   AS order_key,
    i.i_color,
    i.i_size,
    i.i_units
  FROM cs
  FULL OUTER JOIN ss ON cs.cs_item_sk = ss.ss_item_sk
  LEFT JOIN wr ON COALESCE(cs.cs_bill_customer_sk, ss.ss_customer_sk) = wr.wr_refunded_customer_sk
  JOIN item i ON COALESCE(cs.cs_item_sk, ss.ss_item_sk) = i.i_item_sk
  JOIN date_dim d_year ON COALESCE(cs.cs_sold_date_sk, ss.ss_sold_date_sk) = d_year.d_date_sk
  WHERE COALESCE(cs.cs_order_number, ss.ss_ticket_number) NOT IN (SELECT cs_order_number FROM order_excl)
    AND i.i_color = 'Red'
    AND i.i_size = 'M'
    AND i.i_units = 'EA'
),
agg AS (
  SELECT
    item_sk,
    i_brand,
    i_category,
    d_year,
    SUM(sales_amount) AS total_sales,
    SUM(profit_amount) AS net_profit,
    COUNT(DISTINCT order_key) AS distinct_orders
  FROM base
  GROUP BY item_sk, i_brand, i_category, d_year
  HAVING SUM(sales_amount) > 5000
)
SELECT
  a.item_sk,
  a.i_brand,
  a.i_category,
  a.d_year,
  a.total_sales,
  a.net_profit,
  a.distinct_orders,
  ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank,
  (SELECT MAX(d_date) FROM date_dim dmax WHERE dmax.d_year = a.d_year) AS max_date_in_year
FROM agg a
ORDER BY a.total_sales DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY

WITH
  /*
   * Ranked catalog sales (central fact) joined to all its dimensions.
   * Uses a FULL OUTER JOIN to catalog_page as required.
   */
  cs_ranked AS (
    SELECT
      cs.cs_order_number                      AS order_id,
      cs.cs_ext_sales_price                  AS sales_price,
      cs.cs_net_profit                       AS profit,
      d_sold.d_year,
      i.i_category,
      ca.ca_state,
      cd.cd_gender,
      cp.cp_department,
      ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d_sold.d_year = 2002
      AND ca.ca_state = 'CA'
      AND i.i_category = 'Electronics'
  ),

  /*
   * Ranked web sales (second fact) joined to its dimensions.
   */
  ws_ranked AS (
    SELECT
      ws.ws_order_number                     AS order_id,
      ws.ws_ext_sales_price                  AS sales_price,
      ws.ws_net_profit                       AS profit,
      d_ws.d_year,
      i2.i_category,
      ca2.ca_state,
      cd2.cd_gender,
      NULL                                   AS cp_department,
      ROW_NUMBER() OVER (PARTITION BY d_ws.d_year ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM web_sales ws
    LEFT JOIN date_dim d_ws
      ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN item i2
      ON ws.ws_item_sk = i2.i_item_sk
    LEFT JOIN customer c2
      ON ws.ws_bill_customer_sk = c2.c_customer_sk
    LEFT JOIN customer_address ca2
      ON ws.ws_bill_addr_sk = ca2.ca_address_sk
    LEFT JOIN customer_demographics cd2
      ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    WHERE d_ws.d_year = 2002
      AND ca2.ca_state = 'NY'
      AND i2.i_category = 'Books'
  ),

  /*
   * Web returns (third fact) – we only need its keys for set operations but
   * we still join the required dimensions, including the REASON table.
   */
  wr_keys AS (
    SELECT
      wr.wr_order_number                     AS order_id,
      r.r_reason_desc
    FROM web_returns wr
    JOIN web_sales ws2
      ON wr.wr_order_number = ws2.ws_order_number
    LEFT JOIN date_dim d_wr
      ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN item i3
      ON wr.wr_item_sk = i3.i_item_sk
    LEFT JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c3
      ON wr.wr_refunded_customer_sk = c3.c_customer_sk
    LEFT JOIN customer_address ca3
      ON wr.wr_refunded_addr_sk = ca3.ca_address_sk
    WHERE d_wr.d_year = 2002
      AND r.r_reason_desc LIKE '%price%'
  ),

  /*
   * Union of the two ranked facts – UNION DISTINCT is required for the
   * later set‑operations.
   */
  combined AS (
    SELECT * FROM cs_ranked
    UNION DISTINCT
    SELECT * FROM ws_ranked
  ),

  /*
   * EXCEPT – orders that appear in the combined set but have never been
   * returned (according to the filtered web_returns).
   */
  orders_not_returned AS (
    SELECT order_id FROM combined
    EXCEPT
    SELECT order_id FROM wr_keys
  ),

  /*
   * INTERSECT – orders that appear both in the combined set and in the
   * filtered web_returns.
   */
  orders_returned AS (
    SELECT order_id FROM combined
    INTERSECT
    SELECT order_id FROM wr_keys
  ),

  /*
   * Aggregate using GROUP BY CUBE over the three dimensions.
   */
  agg_cube AS (
    SELECT
      d_year,
      i_category,
      ca_state,
      SUM(sales_price) AS total_sales,
      COUNT(DISTINCT order_id) AS order_cnt
    FROM combined
    GROUP BY CUBE (d_year, i_category, ca_state)
  )

SELECT
  c.order_id,
  c.sales_price,
  c.profit,
  c.d_year,
  c.i_category,
  c.ca_state,
  c.sales_rank,
  a.total_sales,
  a.order_cnt,
  CASE
    WHEN c.order_id IN (SELECT order_id FROM orders_returned) THEN 'Returned'
    ELSE 'NotReturned'
  END AS return_flag
FROM combined c
LEFT JOIN agg_cube a
  ON (c.d_year = a.d_year OR a.d_year IS NULL)
 AND (c.i_category = a.i_category OR a.i_category IS NULL)
 AND (c.ca_state = a.ca_state OR a.ca_state IS NULL)
WHERE c.order_id IN (SELECT order_id FROM orders_not_returned)
ORDER BY c.d_year DESC, c.sales_price DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

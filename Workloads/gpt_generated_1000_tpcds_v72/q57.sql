WITH
  web_sales_agg AS (
    SELECT
      ws.ws_sold_date_sk AS sale_date_sk,
      ws.ws_item_sk AS item_sk,
      i.i_category AS category,
      SUM(ws.ws_net_paid) AS total_amount,
      CASE WHEN i.i_current_price > 100 THEN 'high' ELSE 'low' END AS label
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN inventory inv ON ws.ws_item_sk = inv.inv_item_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND i.i_color = 'Red'
      AND ca.ca_location_type = 'single family'
      AND wsite.web_country = 'United States'
      AND wp.wp_char_count > 1000
    GROUP BY ws.ws_sold_date_sk,
             ws.ws_item_sk,
             i.i_category,
             CASE WHEN i.i_current_price > 100 THEN 'high' ELSE 'low' END
  ),

  catalog_sales_agg AS (
    SELECT
      cs.cs_sold_date_sk AS sale_date_sk,
      cs.cs_item_sk AS item_sk,
      i.i_category AS category,
      SUM(cs.cs_net_paid) AS total_amount,
      CASE WHEN i.i_current_price > 100 THEN 'high' ELSE 'low' END AS label
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE t.t_hour BETWEEN 9 AND 19
      AND cc.cc_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND ca.ca_state = 'CA'
      AND i.i_size = 'M'
    GROUP BY cs.cs_sold_date_sk,
             cs.cs_item_sk,
             i.i_category,
             CASE WHEN i.i_current_price > 100 THEN 'high' ELSE 'low' END
  ),

  store_sales_agg AS (
    SELECT
      ss.ss_sold_date_sk AS sale_date_sk,
      ss.ss_item_sk AS item_sk,
      i.i_category AS category,
      SUM(ss.ss_net_paid) AS total_amount,
      CASE WHEN s.s_state = 'TX' THEN 'TX' ELSE 'Other' END AS label
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE t.t_hour BETWEEN 6 AND 22
      AND s.s_state = 'TX'
      AND i.i_brand = 'Brand#12'
      AND ca.ca_location_type = 'apartment'
      AND c.c_preferred_cust_flag = 'N'
    GROUP BY ss.ss_sold_date_sk,
             ss.ss_item_sk,
             i.i_category,
             CASE WHEN s.s_state = 'TX' THEN 'TX' ELSE 'Other' END
  ),

  web_returns_agg AS (
    SELECT
      wr.wr_returned_date_sk AS sale_date_sk,
      wr.wr_item_sk AS item_sk,
      i.i_category AS category,
      SUM(wr.wr_return_amt) AS total_amount,
      CASE WHEN r.r_reason_desc LIKE '%defect%' THEN 'defect' ELSE 'other' END AS label
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE t.t_hour BETWEEN 0 AND 23
      AND i.i_color = 'Blue'
      AND r.r_reason_desc IS NOT NULL
      AND ca.ca_county = 'Washington County'
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY wr.wr_returned_date_sk,
             wr.wr_item_sk,
             i.i_category,
             CASE WHEN r.r_reason_desc LIKE '%defect%' THEN 'defect' ELSE 'other' END
  ),

  set_filtered AS (
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    EXCEPT
    SELECT * FROM web_returns_agg
  ),

  final_agg AS (
    SELECT
      sale_date_sk,
      item_sk,
      category,
      label,
      SUM(total_amount) AS sum_total,
      AVG(total_amount) AS avg_total,
      COUNT(*) AS cnt_rows,
      ROW_NUMBER() OVER (PARTITION BY label ORDER BY SUM(total_amount) DESC) AS rn
    FROM set_filtered
    WHERE total_amount > (SELECT AVG(total_amount) FROM set_filtered)
    GROUP BY sale_date_sk, item_sk, category, label
    HAVING SUM(total_amount) > 500
  )
SELECT *
FROM final_agg
ORDER BY sum_total DESC
LIMIT 100

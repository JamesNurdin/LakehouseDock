WITH
  cs_agg AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_call_center_sk,
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_bill_addr_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_catalog_page_sk,
      SUM(cs.cs_net_paid)          AS total_net_paid,
      COUNT(*)                     AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_list_price > 50
      AND cs.cs_quantity >= 1
      AND cs.cs_call_center_sk IN (
        SELECT cc.cc_call_center_sk FROM call_center cc WHERE cc.cc_state = 'CA'
      )
    GROUP BY
      cs.cs_item_sk,
      cs.cs_call_center_sk,
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_bill_addr_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_catalog_page_sk
  ),

  union_data AS (
    -- First branch: aggregate by call center and year
    SELECT
      cc.cc_name                         AS dim1,
      d_sold.d_year                      AS dim2,
      SUM(a.total_net_paid)              AS sum_net_paid,
      SUM(a.sales_cnt)                   AS sum_sales_cnt,
      LAG(SUM(a.total_net_paid)) OVER (PARTITION BY cc.cc_name ORDER BY d_sold.d_year) AS prev_year_net
    FROM cs_agg a
    JOIN call_center cc               ON a.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold               ON a.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold               ON a.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer_address ca          ON a.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd     ON a.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp              ON a.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr           ON a.cs_order_number = cr.cr_order_number
                                        AND a.cs_item_sk = cr.cr_item_sk
    LEFT JOIN LATERAL (
      SELECT MAX(ws.ws_net_paid) AS max_ws_net_paid
      FROM web_sales ws
      WHERE ws.ws_item_sk = a.cs_item_sk
        AND ws.ws_sold_date_sk = a.cs_sold_date_sk
    ) ws_max ON TRUE
    WHERE d_sold.d_year = 1999
      AND t_sold.t_hour BETWEEN 8 AND 12
      AND cc.cc_state = 'CA'
      AND ca.ca_country = 'United States'
      AND cd.cd_gender = 'F'
      AND cp.cp_department = 'Electronics'
      AND EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_order_number = a.cs_order_number
          AND cr2.cr_return_quantity > 0
      )
    GROUP BY cc.cc_name, d_sold.d_year

    UNION

    -- Second branch: aggregate by catalog department and month sequence
    SELECT
      cp.cp_department                    AS dim1,
      d_sold.d_month_seq                  AS dim2,
      SUM(a.total_net_paid)               AS sum_net_paid,
      SUM(a.sales_cnt)                    AS sum_sales_cnt,
      NULL                                 AS prev_year_net
    FROM cs_agg a
    JOIN call_center cc               ON a.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold               ON a.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold               ON a.cs_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_page cp              ON a.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca          ON a.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd     ON a.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr           ON a.cs_order_number = cr.cr_order_number
                                        AND a.cs_item_sk = cr.cr_item_sk
    LEFT JOIN LATERAL (
      SELECT MAX(ws.ws_net_paid) AS max_ws_net_paid
      FROM web_sales ws
      WHERE ws.ws_item_sk = a.cs_item_sk
        AND ws.ws_sold_date_sk = a.cs_sold_date_sk
    ) ws_max ON TRUE
    WHERE d_sold.d_year = 1999
      AND t_sold.t_hour BETWEEN 8 AND 12
      AND cc.cc_state = 'CA'
      AND ca.ca_country = 'United States'
      AND cd.cd_gender = 'F'
      AND cp.cp_department = 'Electronics'
    GROUP BY cp.cp_department, d_sold.d_month_seq
  )
SELECT
  dim1,
  dim2,
  SUM(sum_net_paid)   AS total_net_paid,
  SUM(sum_sales_cnt)  AS total_sales_cnt,
  MAX(prev_year_net)  AS prev_year_net
FROM union_data
GROUP BY dim1, dim2
ORDER BY dim1, dim2

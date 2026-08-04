WITH
  intersect_orders AS (
    SELECT cs_order_number AS order_number FROM catalog_sales
    INTERSECT
    SELECT ws_order_number AS order_number FROM web_sales
  ),
  sampled_warehouse AS (
    SELECT * FROM warehouse TABLESAMPLE BERNOULLI (10)
  ),
  page_array AS (
    SELECT wp_web_page_sk,
           ARRAY[wp_url, wp_type] AS attr_array
    FROM web_page
  ),
  joined AS (
    SELECT
      cs.cs_order_number               AS cs_order_number,
      cs.cs_sold_date_sk               AS cs_sold_date_sk,
      cs.cs_quantity                   AS cs_quantity,
      cs.cs_net_paid                   AS cs_net_paid,
      cc.cc_name                       AS cc_name,
      cp.cp_department                 AS cp_department,
      p.p_promo_name                   AS p_promo_name,
      sm.sm_type                       AS sm_type,
      w.w_warehouse_name               AS w_warehouse_name,
      s.s_store_name                   AS s_store_name,
      cd_bill.cd_gender                AS bill_gender,
      cd_ship.cd_gender                AS ship_gender,
      ca_bill.ca_city                  AS bill_city,
      ca_ship.ca_city                  AS ship_city,
      t.t_hour                         AS t_hour,
      wp.wp_url                        AS wp_url,
      u.val                            AS page_attribute,
      wr.wr_return_amt                 AS wr_return_amt,
      row_number() OVER (PARTITION BY s.s_store_name ORDER BY cs.cs_net_paid DESC) AS rn_store,
      rank()        OVER (ORDER BY cs.cs_net_paid DESC)                     AS rnk_overall
    FROM catalog_sales cs
    JOIN intersect_orders io ON cs.cs_order_number = io.order_number
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN sampled_warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    JOIN store_sales ss ON ss.ss_sold_time_sk = cs.cs_sold_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN page_array pa ON wp.wp_web_page_sk = pa.wp_web_page_sk
    CROSS JOIN UNNEST(pa.attr_array) AS u(val)
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN customer_demographics wr_cd ON wr.wr_refunded_cdemo_sk = wr_cd.cd_demo_sk
    JOIN customer_address wr_ca ON wr.wr_refunded_addr_sk = wr_ca.ca_address_sk
  ),
  final AS (
    SELECT
      rn_store,
      rnk_overall,
      cs_order_number,
      cs_sold_date_sk,
      cs_quantity,
      cs_net_paid,
      cc_name,
      cp_department,
      p_promo_name,
      sm_type,
      w_warehouse_name,
      s_store_name,
      bill_gender,
      ship_gender,
      bill_city,
      ship_city,
      t_hour,
      wp_url,
      page_attribute,
      wr_return_amt
    FROM joined
  )
SELECT *
FROM final
ORDER BY cs_net_paid DESC
LIMIT 100

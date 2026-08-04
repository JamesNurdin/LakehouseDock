WITH
  cs_sample AS (
    SELECT *
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  rc1 AS (
    SELECT cr_order_number
    FROM tpcds.catalog_returns
    WHERE cr_return_amount > 1000
  ),
  rc2 AS (
    SELECT cr_order_number
    FROM tpcds.catalog_returns
    WHERE cr_return_quantity > 5
  ),
  intersect_orders AS (
    SELECT cr_order_number FROM rc1
    INTERSECT
    SELECT cr_order_number FROM rc2
  ),
  scalar_max_net_paid AS (
    SELECT MAX(cs_net_paid) AS max_net_paid
    FROM tpcds.catalog_sales
    WHERE cs_quantity = 1
  ),
  final_agg AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      cc.cc_name,
      sm.sm_type,
      p.p_promo_name,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      ca.ca_city,
      td.t_hour,
      store.s_store_name,
      ws.ws_order_number,
      ws_site.web_name,
      COUNT(*) AS sales_cnt,
      SUM(cs.cs_net_paid) AS total_net_paid,
      AVG(cs.cs_quantity) AS avg_quantity,
      MIN(cs.cs_net_paid) AS min_net_paid,
      MAX(cs.cs_net_paid) AS max_net_paid,
      COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
      COUNT(DISTINCT i.i_brand) AS distinct_brands,
      SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_on_hand
    FROM cs_sample cs
    JOIN tpcds.item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN tpcds.store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.store
      ON sr.sr_store_sk = store.s_store_sk
    LEFT JOIN tpcds.web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_site ws_site
      ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN tpcds.web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN tpcds.catalog_returns cr
      ON cr.cr_item_sk = i.i_item_sk
     AND cr.cr_order_number = cs.cs_order_number
    WHERE
      cc.cc_division = 3
      AND i.i_current_price > 100
      AND ca.ca_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND cs.cs_net_paid > (SELECT max_net_paid FROM scalar_max_net_paid)
      AND cs.cs_order_number IN (SELECT cr_order_number FROM intersect_orders)
    GROUP BY
      i.i_item_id,
      i.i_product_name,
      cc.cc_name,
      sm.sm_type,
      p.p_promo_name,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      ca.ca_city,
      td.t_hour,
      store.s_store_name,
      ws.ws_order_number,
      ws_site.web_name
  )
SELECT
  *,
  ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY total_net_paid DESC) AS rank_by_net_paid
FROM final_agg
ORDER BY total_net_paid DESC
LIMIT 100

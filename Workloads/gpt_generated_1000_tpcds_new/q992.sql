WITH
  common_orders AS (
    SELECT cs_order_number FROM catalog_sales
    INTERSECT
    SELECT ws_order_number FROM web_sales
  ),
  sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  )
SELECT
  agg.d_year,
  agg.w_warehouse_name,
  agg.i_item_id,
  agg.c_customer_id,
  agg.cd_gender,
  agg.cc_name,
  agg.cp_department,
  agg.r_reason_desc,
  agg.catalog_net_paid,
  agg.web_net_paid,
  ROW_NUMBER() OVER (PARTITION BY agg.w_warehouse_name ORDER BY agg.catalog_net_paid DESC) AS sales_rank
FROM (
  SELECT
    d.d_year,
    w.w_warehouse_name,
    i1.i_item_id,
    c.c_customer_id,
    cd.cd_gender,
    cc.cc_name,
    cp.cp_department,
    r.r_reason_desc,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    SUM(ws.ws_net_paid) AS web_net_paid
  FROM
    catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i1 ON cs.cs_item_sk = i1.i_item_sk               -- first use of ITEM
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN LATERAL (
      SELECT cr.cr_reason_sk
      FROM catalog_returns cr
      WHERE cr.cr_order_number = cs.cs_order_number
      ORDER BY cr.cr_return_amount DESC
      FETCH FIRST 1 ROW ONLY
    ) cr_lat ON TRUE
    JOIN reason r ON cr_lat.cr_reason_sk = r.r_reason_sk
    JOIN sampled_inventory inv ON inv.inv_item_sk = i1.i_item_sk
                                AND inv.inv_warehouse_sk = w.w_warehouse_sk
                                AND inv.inv_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_item_sk = i1.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i1.i_item_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk                -- second use of ITEM under a different alias
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
  WHERE
    cs.cs_order_number IN (SELECT cs_order_number FROM common_orders)
    AND NOT EXISTS (
      SELECT 1 FROM catalog_returns cr2
      WHERE cr2.cr_order_number = cs.cs_order_number
        AND cr2.cr_return_quantity > 0
    )
  GROUP BY GROUPING SETS (
    (d.d_year, w.w_warehouse_name, i1.i_item_id, c.c_customer_id, cd.cd_gender, cc.cc_name, cp.cp_department, r.r_reason_desc),
    (d.d_year, w.w_warehouse_name, i1.i_item_id),
    (d.d_year, w.w_warehouse_name),
    (d.d_year)
  )
) agg
ORDER BY agg.d_year DESC, agg.w_warehouse_name, agg.catalog_net_paid DESC
LIMIT 100

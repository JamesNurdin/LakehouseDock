WITH
  -- Sample a fraction of the inventory table
  sample_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),

  -- Full outer join between store and its returns (allowed join key)
  full_store_returns AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      sr.sr_item_sk,
      sr.sr_returned_date_sk,
      sr.sr_return_quantity,
      sr.sr_reason_sk
    FROM store s
    FULL OUTER JOIN store_returns sr
      ON s.s_store_sk = sr.sr_store_sk
  ),

  -- First level aggregation
  base_agg AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      d.d_year,
      d.d_month_seq,
      w.w_warehouse_name,
      cc.cc_name,
      fs.s_store_name,
      SUM(cs.cs_ext_sales_price)                         AS total_sales,
      SUM(cs.cs_net_profit)                              AS total_profit,
      COUNT(DISTINCT cs.cs_order_number)                AS order_cnt,
      SUM(COALESCE(fs.sr_return_quantity, 0))           AS total_store_returns,
      SUM(COALESCE(wr.wr_return_quantity, 0))           AS total_web_returns,
      SUM(COALESCE(inv.inv_quantity_on_hand, 0))        AS total_on_hand,
      AVG(ws.ws_net_paid)                               AS avg_ws_net_paid,
      MAX(d.d_date)                                     AS latest_sale_date
    FROM catalog_sales cs
      JOIN item i                 ON cs.cs_item_sk = i.i_item_sk
      JOIN date_dim d             ON cs.cs_sold_date_sk = d.d_date_sk
      JOIN warehouse w            ON cs.cs_warehouse_sk = w.w_warehouse_sk
      JOIN call_center cc         ON cs.cs_call_center_sk = cc.cc_call_center_sk
      LEFT JOIN full_store_returns fs
        ON cs.cs_item_sk = fs.sr_item_sk
       AND cs.cs_sold_date_sk = fs.sr_returned_date_sk
      LEFT JOIN sample_inventory inv
        ON cs.cs_item_sk = inv.inv_item_sk
       AND cs.cs_sold_date_sk = inv.inv_date_sk
      LEFT JOIN web_sales ws
        ON cs.cs_order_number = ws.ws_order_number
      LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
      LEFT JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
      LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
      LEFT JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      LEFT JOIN reason r                ON fs.sr_reason_sk = r.r_reason_sk
      LEFT JOIN web_page wp             ON ws.ws_web_page_sk = wp.wp_web_page_sk
      LEFT JOIN web_site we             ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ca.ca_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND w.w_warehouse_name LIKE '%Warehouse%'
      AND d.d_holiday = 'N'
    GROUP BY
      i.i_item_id,
      i.i_product_name,
      d.d_year,
      d.d_month_seq,
      w.w_warehouse_name,
      cc.cc_name,
      fs.s_store_name
  )
SELECT
  ba.i_item_id,
  ba.i_product_name,
  ba.d_year,
  ba.d_month_seq,
  ba.w_warehouse_name,
  ba.cc_name,
  ba.s_store_name,
  ba.total_sales,
  ba.total_profit,
  ba.order_cnt,
  ba.total_store_returns,
  ba.total_web_returns,
  ba.total_on_hand,
  ba.avg_ws_net_paid,
  ba.latest_sale_date,
  -- Correlated scalar subquery: total number of orders for the same item
  (SELECT COUNT(*) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = i.i_item_sk) AS total_orders_for_item,
  metric
FROM base_agg ba
  JOIN item i ON ba.i_item_id = i.i_item_id
  -- Expand an array (total_sales, total_profit) per row
  CROSS JOIN UNNEST(ARRAY[ba.total_sales, ba.total_profit]) AS t(metric)
WHERE ba.total_sales > 10000
  AND ba.total_profit > 0
  AND ba.total_on_hand IS NOT NULL
  AND ba.avg_ws_net_paid < 5000
ORDER BY ba.total_sales DESC
LIMIT 100

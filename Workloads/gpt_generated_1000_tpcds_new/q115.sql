WITH
  catalog_item_sales AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_net_profit,
      cs.cs_quantity,
      cs.cs_order_number,
      cs.cs_warehouse_sk,
      cs.cs_promo_sk,
      cs.cs_call_center_sk,
      cs.cs_bill_addr_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_hdemo_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d                     ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i                         ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p                   ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.customer_address ca           ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN tpcds.inventory inv            ON inv.inv_item_sk = i.i_item_sk
                                             AND inv.inv_warehouse_sk = w.w_warehouse_sk
                                             AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_returns cr      ON cr.cr_order_number = cs.cs_order_number
                                             AND cr.cr_item_sk = cs.cs_item_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND p.p_purpose = 'Unknown'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '500-1000'
      AND i.i_brand = 'Brand#12'
      AND cc.cc_name = 'Call Center 1'
      AND ib.ib_upper_bound > 50000
  ),

  web_item_sales AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      ws.ws_net_profit,
      ws.ws_quantity,
      ws.ws_order_number,
      ws.ws_warehouse_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d2                ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN tpcds.web_returns wr            ON ws.ws_order_number = wr.wr_order_number
                                         AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d2.d_year = 2001
      AND ws.ws_warehouse_sk IN (3,5,8)
      AND ws.ws_quantity > 2
      AND ws.ws_coupon_amt > 0
  ),

  catalog_vs_web AS (
    SELECT DISTINCT cs.cs_item_sk
    FROM catalog_item_sales cs
    EXCEPT
    SELECT DISTINCT ws.ws_item_sk
    FROM web_item_sales ws
  ),

  ranked_items AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      SUM(cs.cs_net_profit) AS total_profit,
      SUM(cs.cs_quantity) AS total_qty,
      RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
      CASE WHEN SUM(cs.cs_quantity) > 1000 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i                       ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_vs_web cvw                 ON cs.cs_item_sk = cvw.cs_item_sk
    GROUP BY i.i_item_id, i.i_product_name
  )
SELECT
  ri.i_item_id,
  ri.i_product_name,
  ri.total_profit,
  ri.total_qty,
  ri.profit_rank,
  ri.volume_category
FROM ranked_items ri
WHERE ri.profit_rank <= 10
ORDER BY ri.profit_rank

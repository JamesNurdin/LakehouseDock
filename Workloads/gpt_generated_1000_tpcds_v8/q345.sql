WITH base1 AS (
   SELECT
      cs.cs_order_number,
      d.d_year,
      i.i_item_sk,
      i.i_category,
      i.i_current_price,
      cs.cs_net_profit,
      cs.cs_ext_discount_amt,
      c.c_customer_sk,
      c.c_birth_month,
      s.s_store_sk,
      s.s_state,
      w.w_warehouse_sk,
      w.w_gmt_offset,
      cc.cc_call_center_sk,
      cp.cp_catalog_page_sk,
      sm.sm_ship_mode_sk,
      sr.sr_return_quantity,
      wr.wr_return_quantity,
      wp.wp_type,
      t.t_hour,
      inv.inv_quantity_on_hand,
      CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
   LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
   LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
     AND i.i_current_price BETWEEN 20 AND 200
     AND s.s_state = 'TX'
     AND c.c_birth_month IN (5,6,7)
     AND w.w_gmt_offset = -6.00
     AND cp.cp_type = 'PROMO'
     AND wp.wp_type = 'USER'
     AND t.t_hour BETWEEN 9 AND 17
),
base2 AS (
   SELECT
      cs.cs_order_number,
      d.d_year,
      i.i_item_sk,
      i.i_category,
      i.i_current_price,
      cs.cs_net_profit,
      cs.cs_ext_discount_amt,
      c.c_customer_sk,
      c.c_birth_month,
      s.s_store_sk,
      s.s_state,
      w.w_warehouse_sk,
      w.w_gmt_offset,
      cc.cc_call_center_sk,
      cp.cp_catalog_page_sk,
      sm.sm_ship_mode_sk,
      sr.sr_return_quantity,
      wr.wr_return_quantity,
      wp.wp_type,
      t.t_hour,
      inv.inv_quantity_on_hand,
      CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
   LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
   LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
   WHERE d.d_year = 2003
     AND i.i_current_price BETWEEN 50 AND 500
     AND s.s_state = 'CA'
     AND c.c_birth_month IN (8,9,10)
     AND w.w_gmt_offset = -8.00
     AND cp.cp_type = 'STANDARD'
     AND wp.wp_type = 'CONTENT'
     AND t.t_hour BETWEEN 18 AND 23
),
combined AS (
   SELECT * FROM base1
   UNION DISTINCT
   SELECT * FROM base2
),
aggregated AS (
   SELECT
      c_year,
      i_category,
      profit_flag,
      SUM(cs_net_profit) AS sum_profit,
      AVG(cs_ext_discount_amt) AS avg_discount,
      COUNT(DISTINCT c_customer_sk) AS unique_customers
   FROM (
      SELECT
         d_year AS c_year,
         i_category,
         cs_net_profit,
         cs_ext_discount_amt,
         c_customer_sk,
         profit_flag,
         i_item_sk
      FROM combined b
      WHERE EXISTS (
         SELECT 1 FROM store_returns sr2
         WHERE sr2.sr_customer_sk = b.c_customer_sk
           AND sr2.sr_return_quantity > 0
      )
   ) sub
   GROUP BY c_year, i_category, profit_flag
   HAVING SUM(cs_net_profit) > 1000
)
SELECT
   a.c_year,
   a.i_category,
   a.profit_flag,
   a.sum_profit,
   a.avg_discount,
   a.unique_customers,
   mp.max_profit
FROM aggregated a
CROSS JOIN LATERAL (
   SELECT MAX(cs.cs_net_profit) AS max_profit
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE i.i_category = a.i_category
) mp
ORDER BY a.sum_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY

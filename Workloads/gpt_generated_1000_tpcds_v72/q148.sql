WITH
  agg_sales AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_sold_time_sk,
      cs.cs_warehouse_sk,
      cs.cs_order_number,
      cs.cs_catalog_page_sk,
      cs.cs_bill_addr_sk,
      cs.cs_ship_addr_sk,
      cs.cs_promo_sk,
      SUM(cs.cs_ext_sales_price)   AS total_sales_amount,
      SUM(cs.cs_net_profit)        AS total_net_profit
    FROM catalog_sales cs
    GROUP BY
      cs.cs_item_sk,
      cs.cs_sold_time_sk,
      cs.cs_warehouse_sk,
      cs.cs_order_number,
      cs.cs_catalog_page_sk,
      cs.cs_bill_addr_sk,
      cs.cs_ship_addr_sk,
      cs.cs_promo_sk
  ),
  sales_detail AS (
    SELECT
      w.w_warehouse_id,
      w.w_state,
      i.i_category,
      i.i_brand,
      a.total_sales_amount,
      a.total_net_profit,
      CASE WHEN a.total_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
      t.t_hour,
      r.r_reason_desc,
      wp.wp_type,
      p.p_promo_name
    FROM agg_sales a
    JOIN item i                 ON a.cs_item_sk     = i.i_item_sk
    JOIN warehouse w            ON a.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t             ON a.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p            ON a.cs_promo_sk   = p.p_promo_sk
    JOIN catalog_page cp        ON a.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_bill  ON a.cs_bill_addr_sk   = ca_bill.ca_address_sk
    JOIN customer_address ca_ship  ON a.cs_ship_addr_sk   = ca_ship.ca_address_sk
    -- Catalog returns and related dimensions
    JOIN catalog_returns cr     ON cr.cr_order_number = a.cs_order_number
                                 AND cr.cr_item_sk     = a.cs_item_sk
    JOIN reason r               ON cr.cr_reason_sk   = r.r_reason_sk
    JOIN catalog_page cp_ret    ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    JOIN warehouse w_ret        ON cr.cr_warehouse_sk    = w_ret.w_warehouse_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    -- Web sales and related dimensions
    JOIN web_sales ws           ON ws.ws_item_sk      = i.i_item_sk
                                 AND ws.ws_warehouse_sk = w.w_warehouse_sk
                                 AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp            ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site webs          ON ws.ws_web_site_sk = webs.web_site_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    -- Web returns and related dimensions
    JOIN web_returns wr         ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk     = ws.ws_item_sk
    JOIN reason r2              ON wr.wr_reason_sk   = r2.r_reason_sk
    JOIN web_page wp_ret        ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
    JOIN customer_address ca_wr_ref ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
    JOIN customer_address ca_wr_ret ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND w.w_state = 'CA'
      AND t.t_hour BETWEEN 8 AND 12
  ),
  aggregated AS (
    SELECT
      sd.w_warehouse_id,
      sd.i_category,
      SUM(sd.total_sales_amount)                                                  AS warehouse_category_sales,
      AVG(sd.total_net_profit)                                                    AS avg_net_profit,
      SUM(CASE WHEN sd.profit_flag = 'Profitable' THEN sd.total_sales_amount ELSE 0 END) AS profitable_sales
    FROM sales_detail sd
    GROUP BY sd.w_warehouse_id, sd.i_category
  )
SELECT
  a.w_warehouse_id,
  a.i_category,
  a.warehouse_category_sales,
  a.avg_net_profit,
  a.profitable_sales,
  ROW_NUMBER() OVER (PARTITION BY a.w_warehouse_id ORDER BY a.warehouse_category_sales DESC) AS sales_rank
FROM aggregated a
ORDER BY a.warehouse_category_sales DESC
LIMIT 100

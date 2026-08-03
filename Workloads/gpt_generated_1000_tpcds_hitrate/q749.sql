WITH
  store_ret_agg AS (
    SELECT
      sr_item_sk,
      sr_returned_date_sk,
      sr_addr_sk,
      SUM(sr_return_quantity) AS total_return_qty,
      SUM(sr_return_amt)       AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk, sr_returned_date_sk, sr_addr_sk
  ),
  exclusive_items AS (
    SELECT ws_item_sk FROM web_sales
    EXCEPT
    SELECT cs_item_sk FROM catalog_sales
  ),
  aggregated AS (
    SELECT
      d.d_year,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      SUM(cs.cs_net_paid)      AS catalog_sales_amount,
      SUM(ws.ws_net_paid)      AS web_sales_amount,
      COALESCE(SUM(sra.total_return_amt), 0) AS total_return_amount,
      SUM(cs.cs_net_profit)    AS total_profit
    FROM date_dim d
    JOIN catalog_sales cs           ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t                 ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w                ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i                     ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p                ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill   ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship   ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr    ON cr.cr_order_number = cs.cs_order_number
                                     AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws              ON ws.ws_sold_date_sk = d.d_date_sk
                                     AND ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t_ws              ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we                ON ws.ws_web_site_sk = we.web_site_sk
    JOIN store_ret_agg sra         ON sra.sr_item_sk = i.i_item_sk
                                     AND sra.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca_ret   ON ca_ret.ca_address_sk = sra.sr_addr_sk
    WHERE i.i_item_sk NOT IN (SELECT ws_item_sk FROM exclusive_items)
    GROUP BY ROLLUP (d.d_year, i.i_category, i.i_brand, p.p_promo_name)
  )
SELECT
  a.d_year,
  a.i_category,
  a.i_brand,
  a.p_promo_name,
  a.catalog_sales_amount,
  a.web_sales_amount,
  a.total_return_amount,
  CASE WHEN a.total_profit > (SELECT AVG(cs_net_profit) FROM catalog_sales)
       THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category,
  ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.catalog_sales_amount DESC) AS sales_rank,
  LAG(a.total_profit) OVER (PARTITION BY a.i_category ORDER BY a.d_year) AS prior_year_profit,
  a.total_profit
FROM aggregated a
ORDER BY a.d_year DESC, a.catalog_sales_amount DESC
LIMIT 100

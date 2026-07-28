WITH joined_data AS (
   SELECT
       ws.ws_order_number,
       w_sales.w_warehouse_name AS warehouse_name,
       i_sales.i_category AS category,
       i_sales.i_brand AS brand,
       wp_sales.wp_type AS sales_page_type,
       i_return.i_color AS return_item_color,
       wp_return.wp_type AS return_page_type,
       COALESCE(r.r_reason_desc, 'Unknown') AS reason_desc,
       wr.wr_net_loss AS net_loss,
       wr.wr_return_quantity,
       ws.ws_ext_sales_price,
       ws.ws_net_profit
   FROM web_sales ws
   JOIN item i_sales
     ON ws.ws_item_sk = i_sales.i_item_sk
   JOIN web_page wp_sales
     ON ws.ws_web_page_sk = wp_sales.wp_web_page_sk
   JOIN warehouse w_sales
     ON ws.ws_warehouse_sk = w_sales.w_warehouse_sk
   JOIN web_returns wr
     ON ws.ws_order_number = wr.wr_order_number
   JOIN item i_return
     ON wr.wr_item_sk = i_return.i_item_sk
   JOIN web_page wp_return
     ON wr.wr_web_page_sk = wp_return.wp_web_page_sk
   LEFT JOIN reason r
     ON wr.wr_reason_sk = r.r_reason_sk
   JOIN item i_brand
     ON ws.ws_item_sk = i_brand.i_item_sk
   JOIN web_page wp_extra
     ON ws.ws_web_page_sk = wp_extra.wp_web_page_sk
),
aggregated AS (
   SELECT
       warehouse_name,
       category,
       reason_desc,
       SUM(net_loss) AS total_net_loss,
       COUNT(*) AS return_count
   FROM joined_data
   GROUP BY ROLLUP (warehouse_name, category, reason_desc)
)
SELECT
   warehouse_name,
   category,
   reason_desc,
   total_net_loss,
   return_count,
   ROW_NUMBER() OVER (PARTITION BY warehouse_name ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY warehouse_name, category, reason_desc

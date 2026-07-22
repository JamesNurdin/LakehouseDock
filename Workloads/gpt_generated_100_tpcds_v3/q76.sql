WITH sales_agg AS (
    SELECT
        s.s_store_id,
        ws_site.web_site_id,
        i.i_category,
        d_sales.d_year,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM store_sales ss
    INNER JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
    INNER JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    INNER JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d_sales.d_year = 2001
      AND i.i_category = 'Electronics'
      AND s.s_state = 'CA'
      AND ws_site.web_gmt_offset = -8.00
      AND EXISTS (
          SELECT 1
          FROM call_center cc_sub
          INNER JOIN date_dim d_cc ON cc_sub.cc_closed_date_sk = d_cc.d_date_sk
          WHERE cc_sub.cc_city = s.s_city
            AND cc_sub.cc_tax_percentage > 0.05
            AND d_cc.d_year = 2001
      )
    GROUP BY s.s_store_id, ws_site.web_site_id, i.i_category, d_sales.d_year
)
SELECT
    i_category,
    COUNT(DISTINCT s_store_id) AS store_count,
    SUM(store_sales) AS total_store_sales,
    SUM(web_sales) AS total_web_sales,
    SUM(store_sales + web_sales) AS total_sales,
    AVG(store_sales + web_sales) AS avg_sales_per_store,
    SUM(total_returns) AS total_returns,
    SUM(store_profit + web_profit) AS total_profit,
    CASE WHEN SUM(store_sales + web_sales) > 0
         THEN SUM(store_profit + web_profit) / SUM(store_sales + web_sales)
         ELSE NULL
    END AS profit_margin
FROM sales_agg
GROUP BY i_category
HAVING SUM(store_sales + web_sales) > 100000
ORDER BY total_sales DESC
LIMIT 100

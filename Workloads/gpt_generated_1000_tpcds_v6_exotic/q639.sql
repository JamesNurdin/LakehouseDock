WITH combined AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        p.p_promo_name,
        cp.cp_type,
        ss.ss_ext_sales_price AS store_sales,
        cs.cs_ext_sales_price AS catalog_sales,
        ws.ws_ext_sales_price AS web_sales,
        COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0) AS total_sales,
        CASE WHEN COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0) > 100000 THEN 'High' ELSE 'Normal' END AS sales_category,
        RANK() OVER (
            PARTITION BY d.d_year
            ORDER BY (COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) DESC
        ) AS yearly_rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_current_price > 50
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND cp.cp_type = 'monthly'
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr2 WHERE sr2.sr_item_sk = i.i_item_sk
      )
)
SELECT
    d_year,
    i_item_id,
    i_product_name,
    p_promo_name,
    cp_type,
    store_sales,
    catalog_sales,
    web_sales,
    total_sales,
    sales_category,
    yearly_rank
FROM combined
ORDER BY total_sales DESC
LIMIT 100

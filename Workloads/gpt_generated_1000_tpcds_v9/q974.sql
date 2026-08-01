WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_brand,
        i.i_color,
        i.i_category,
        i.i_class,
        i.i_product_name,
        s.s_store_name,
        s.s_state,
        s.s_city,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        w.w_state,
        cp.cp_catalog_number,
        cp.cp_type,
        ws.web_name,
        ws.web_state
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM call_center cc
          WHERE cc.cc_call_center_id = 'CC_0001'
            AND cc.cc_closed_date_sk = d.d_date_sk
      )
)
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_ext_sales_price) AS avg_sales,
    COUNT(*) AS transaction_count,
    MIN(ss_ext_sales_price) AS min_sale,
    MAX(ss_ext_sales_price) AS max_sale,
    SUM(CASE WHEN i_color = 'Red' THEN ss_ext_sales_price ELSE 0 END) AS red_item_sales
FROM base
GROUP BY s_store_name, d_year, d_month_seq
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100

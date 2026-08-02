WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory
    GROUP BY inv_item_sk
),
sales_data AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        cp.cp_department AS department,
        w.w_warehouse_name AS warehouse_name,
        CAST(NULL AS VARCHAR) AS web_name,
        CAST(NULL AS VARCHAR) AS web_page_url,
        CAST(NULL AS VARCHAR) AS return_reason,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS profit,
        cs.cs_quantity AS quantity,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_sold_time_sk AS sold_time_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cd.cd_gender AS cd_gender,
        c.c_preferred_cust_flag AS preferred_cust_flag,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE i.i_current_price > 50
      AND cp.cp_department = 'Electronics'
      AND w.w_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
),
store_sales_data AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        CAST(NULL AS VARCHAR) AS department,
        CAST(NULL AS VARCHAR) AS warehouse_name,
        CAST(NULL AS VARCHAR) AS web_name,
        CAST(NULL AS VARCHAR) AS web_page_url,
        CAST(NULL AS VARCHAR) AS return_reason,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit,
        ss.ss_quantity AS quantity,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_sold_time_sk AS sold_time_sk,
        CAST(NULL AS INTEGER) AS warehouse_sk,
        cd.cd_gender AS cd_gender,
        c.c_preferred_cust_flag AS preferred_cust_flag,
        'store' AS source
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE i.i_brand = 'Brand#45'
      AND ss.ss_quantity > 0
      AND td.t_hour BETWEEN 8 AND 17
),
web_sales_data AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        CAST(NULL AS VARCHAR) AS department,
        w.w_warehouse_name AS warehouse_name,
        ws_site.web_name AS web_name,
        wp_detail.wp_url AS web_page_url,
        CAST(NULL AS VARCHAR) AS return_reason,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS profit,
        ws.ws_quantity AS quantity,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_sold_time_sk AS sold_time_sk,
        ws.ws_warehouse_sk AS warehouse_sk,
        cd.cd_gender AS cd_gender,
        c.c_preferred_cust_flag AS preferred_cust_flag,
        'web' AS source
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN LATERAL (
        SELECT wp.wp_url
        FROM web_page wp
        WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
    ) wp_detail ON TRUE
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_quantity > 0
      AND ws.ws_ext_sales_price > 100
      AND ws_site.web_country = 'United States'
),
returns_data AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        CAST(NULL AS VARCHAR) AS department,
        CAST(NULL AS VARCHAR) AS warehouse_name,
        CAST(NULL AS VARCHAR) AS web_name,
        CAST(NULL AS VARCHAR) AS web_page_url,
        r.r_reason_desc AS return_reason,
        -wr.wr_return_amt AS sales_amount,
        -wr.wr_net_loss AS profit,
        -wr.wr_return_quantity AS quantity,
        wr.wr_returned_date_sk AS sold_date_sk,
        wr.wr_returned_time_sk AS sold_time_sk,
        CAST(NULL AS INTEGER) AS warehouse_sk,
        cd.cd_gender AS cd_gender,
        c.c_preferred_cust_flag AS preferred_cust_flag,
        'return' AS source
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE r.r_reason_desc LIKE '%Damaged%'
      AND wr.wr_return_quantity > 0
)
SELECT
    sd.category,
    sd.class,
    sd.brand,
    sd.department,
    sd.warehouse_name,
    sd.web_name,
    sd.web_page_url,
    sd.return_reason,
    SUM(sd.sales_amount) AS total_sales_amount,
    SUM(sd.profit) AS total_profit,
    SUM(ia.total_inventory_qty) AS total_inventory_quantity,
    RANK() OVER (PARTITION BY sd.category ORDER BY SUM(sd.profit) DESC) AS category_profit_rank
FROM (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM store_sales_data
    UNION ALL
    SELECT * FROM web_sales_data
    UNION ALL
    SELECT * FROM returns_data
) sd
LEFT JOIN inv_agg ia ON sd.item_sk = ia.inv_item_sk
GROUP BY ROLLUP (sd.category, sd.class, sd.brand, sd.department, sd.warehouse_name, sd.web_name, sd.web_page_url, sd.return_reason)
HAVING SUM(sd.sales_amount) > 0
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY

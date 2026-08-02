/* Goal: Compute profitability per store, year and product by combining sales and returns across catalog, store, and web channels, rank stores by net profit, and demonstrate complex joins, aggregations, a LATERAL subquery, and window functions. */
WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_item_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid) AS total_cs_net_paid
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_ws_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        SUM(cr.cr_return_amount) AS cr_return_amount,
        SUM(cr.cr_return_quantity) AS cr_return_quantity
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk
),
store_returns_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt) AS sr_return_amt,
        SUM(sr.sr_return_quantity) AS sr_return_quantity
    FROM store_returns sr
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS wr_return_amt,
        SUM(wr.wr_return_quantity) AS wr_return_quantity
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
),
all_aggregated AS (
    SELECT
        s.s_store_name AS store_name,
        d_sold.d_year AS year,
        i.i_product_name AS product_name,
        SUM(ss_agg.total_net_profit) AS total_store_profit,
        SUM(cs_agg.total_cs_net_paid) AS total_catalog_sales,
        SUM(ws_agg.total_ws_net_paid) AS total_web_sales,
        SUM(COALESCE(cr_agg.cr_return_amount, 0)) AS total_catalog_returns,
        SUM(COALESCE(sr_agg.sr_return_amt, 0)) AS total_store_returns,
        SUM(COALESCE(wr_agg.wr_return_amt, 0)) AS total_web_returns,
        MAX(cs_lateral.cs_total_discount) AS total_cs_discount
    FROM ss_agg
    JOIN store s
        ON s.s_store_sk = ss_agg.ss_store_sk
    JOIN date_dim d_sold
        ON d_sold.d_date_sk = ss_agg.ss_sold_date_sk
    JOIN item i
        ON i.i_item_sk = ss_agg.ss_item_sk
    -- Bring in detailed store_sales to reach customer and address dimensions
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
        AND ss.ss_sold_date_sk = d_sold.d_date_sk
        AND ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON c.c_customer_sk = ss.ss_customer_sk
    JOIN customer_demographics cd
        ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN customer_address ca
        ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN catalog_sales_agg cs_agg
        ON cs_agg.cs_item_sk = i.i_item_sk
        AND cs_agg.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN web_sales_agg ws_agg
        ON ws_agg.ws_item_sk = i.i_item_sk
        AND ws_agg.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_returns_agg cr_agg
        ON cr_agg.cr_item_sk = i.i_item_sk
        AND cr_agg.cr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN store_returns_agg sr_agg
        ON sr_agg.sr_item_sk = i.i_item_sk
        AND sr_agg.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN web_returns_agg wr_agg
        ON wr_agg.wr_item_sk = i.i_item_sk
        AND wr_agg.wr_returned_date_sk = d_sold.d_date_sk
    -- Web sales provide ship mode, warehouse and web page dimensions
    JOIN web_sales ws2
        ON ws2.ws_item_sk = i.i_item_sk
        AND ws2.ws_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = ws2.ws_ship_mode_sk
    JOIN warehouse w
        ON w.w_warehouse_sk = ws2.ws_warehouse_sk
    JOIN web_page wp
        ON wp.wp_web_page_sk = ws2.ws_web_page_sk
    JOIN date_dim d_wp_creation
        ON d_wp_creation.d_date_sk = wp.wp_creation_date_sk
    JOIN date_dim d_store_closed
        ON d_store_closed.d_date_sk = s.s_closed_date_sk
    CROSS JOIN LATERAL (
        SELECT SUM(cs2.cs_ext_discount_amt) AS cs_total_discount
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
          AND cs2.cs_sold_date_sk = d_sold.d_date_sk
    ) cs_lateral
    WHERE d_sold.d_year = 2002
      AND s.s_state = 'CA'
      AND i.i_color = 'RED'
    GROUP BY s.s_store_name, d_sold.d_year, i.i_product_name
    HAVING SUM(ss_agg.total_net_profit) > 10000
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_store_profit DESC) AS row_num,
    store_name,
    year,
    product_name,
    total_store_profit,
    total_catalog_sales,
    total_web_sales,
    total_catalog_returns,
    total_store_returns,
    total_web_returns,
    total_cs_discount
FROM all_aggregated
ORDER BY total_store_profit DESC
LIMIT 100

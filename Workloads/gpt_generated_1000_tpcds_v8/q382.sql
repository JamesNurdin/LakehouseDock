WITH base_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        d.d_year,
        d.d_month_seq,
        i.i_brand,
        i.i_category,
        sm.sm_type,
        p.p_discount_active,
        cp.cp_type,
        i.i_item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2000
      AND i.i_brand = 'Brand#12'
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
      AND cp.cp_type = 'STANDARD'
),

sales_with_page AS (
    SELECT
        b.*,
        pg.page_sales,
        CASE WHEN b.i_category = 'WOMEN' THEN 'FEMALE' ELSE 'OTHER' END AS category_group
    FROM base_sales b
    CROSS JOIN LATERAL (
        SELECT SUM(cs2.cs_ext_sales_price) AS page_sales
        FROM catalog_sales cs2
        WHERE cs2.cs_catalog_page_sk = b.cs_catalog_page_sk
    ) pg
),

page_agg AS (
    SELECT
        swp.cs_catalog_page_sk,
        swp.category_group,
        COUNT(DISTINCT swp.cs_order_number) AS distinct_orders,
        COUNT(DISTINCT swp.i_item_sk) AS distinct_items,
        SUM(swp.cs_ext_sales_price) AS total_sales,
        SUM(swp.cs_net_profit) AS total_profit,
        SUM(swp.page_sales) AS page_total_sales
    FROM sales_with_page swp
    GROUP BY swp.cs_catalog_page_sk, swp.category_group
),

returns_orders AS (
    SELECT cr.cr_order_number AS order_num
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2000
),

sales_orders AS (
    SELECT cs.cs_order_number AS order_num
    FROM catalog_sales cs
    JOIN date_dim d_sal ON cs.cs_sold_date_sk = d_sal.d_date_sk
    WHERE d_sal.d_year = 2000
),

common_orders AS (
    SELECT order_num FROM sales_orders
    INTERSECT
    SELECT order_num FROM returns_orders
),

final AS (
    SELECT
        pa.cs_catalog_page_sk,
        pa.category_group,
        pa.distinct_orders,
        pa.distinct_items,
        pa.total_sales,
        pa.total_profit,
        pa.page_total_sales,
        s.s_store_id,
        wr.wr_return_quantity,
        ws.web_name,
        RANK() OVER (PARTITION BY pa.category_group ORDER BY pa.total_sales DESC) AS sales_rank
    FROM page_agg pa
    LEFT JOIN date_dim d_store ON d_store.d_year = 2000
    LEFT JOIN store s ON s.s_closed_date_sk = d_store.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = (
        SELECT i2.i_item_sk FROM item i2 WHERE i2.i_brand = 'Brand#12' LIMIT 1
    )
    LEFT JOIN date_dim d_site ON d_site.d_year = 2000
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d_site.d_date_sk
    WHERE pa.cs_catalog_page_sk IN (
        SELECT cs.cs_catalog_page_sk
        FROM catalog_sales cs
        WHERE cs.cs_order_number IN (SELECT order_num FROM common_orders)
    )
)

SELECT
    cs_catalog_page_sk,
    category_group,
    distinct_orders,
    distinct_items,
    total_sales,
    total_profit,
    page_total_sales,
    s_store_id,
    wr_return_quantity,
    web_name,
    sales_rank
FROM final
ORDER BY total_sales DESC, sales_rank
LIMIT 100

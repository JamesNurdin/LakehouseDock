WITH
    -- Sample a fraction of the inventory table
    inv_sample AS (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
    ),
    -- Rollup to get subtotals and a grand total for inventory quantities
    inv_rollup AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS qty_on_hand
        FROM inv_sample
        GROUP BY ROLLUP (inv_item_sk, inv_warehouse_sk)
    ),
    -- Combine catalog sales and store sales with a UNION DISTINCT
    union_sales AS (
        SELECT
            cs.cs_order_number        AS order_number,
            cs.cs_sold_date_sk        AS sold_date_sk,
            cs.cs_item_sk             AS item_sk,
            cs.cs_warehouse_sk        AS warehouse_sk,
            cs.cs_ext_sales_price     AS sales_amount,
            cs.cs_bill_cdemo_sk       AS cdemo_sk,
            cs.cs_bill_hdemo_sk       AS hdemo_sk,
            cs.cs_promo_sk            AS promo_sk,
            CAST(NULL AS integer)     AS store_sk,
            'catalog'                 AS src
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cp.cp_department = 'Electronics'
        UNION DISTINCT
        SELECT
            ss.ss_ticket_number      AS order_number,
            ss.ss_sold_date_sk        AS sold_date_sk,
            ss.ss_item_sk             AS item_sk,
            CAST(NULL AS integer)    AS warehouse_sk,
            ss.ss_ext_sales_price     AS sales_amount,
            ss.ss_cdemo_sk            AS cdemo_sk,
            ss.ss_hdemo_sk            AS hdemo_sk,
            ss.ss_promo_sk            AS promo_sk,
            ss.ss_store_sk            AS store_sk,
            'store'                   AS src
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE s.s_market_id = 1
    ),
    -- Enrich the combined sales with all dimension tables, LATERAL joins and filters
    annotated_sales AS (
        SELECT
            us.*,
            d.d_year,
            i.i_brand,
            i.i_category,
            i.i_current_price,
            w.w_state,
            w.w_gmt_offset,
            cd.cd_gender,
            hd.hd_buy_potential,
            ib.ib_upper_bound,
            p.p_promo_name,
            cr.cr_return_amount,
            rt.r_reason_desc,
            wp_l.wp_url,
            ws_l.web_name
        FROM union_sales us
        JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
        JOIN item i ON us.item_sk = i.i_item_sk
        LEFT JOIN warehouse w ON us.warehouse_sk = w.w_warehouse_sk
        JOIN customer_demographics cd ON us.cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON us.hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk AND p.p_item_sk = i.i_item_sk
        LEFT JOIN catalog_returns cr ON us.order_number = cr.cr_order_number
        LEFT JOIN reason rt ON cr.cr_reason_sk = rt.r_reason_sk
        LEFT JOIN LATERAL (
            SELECT wp.wp_url
            FROM web_page wp
            WHERE wp.wp_creation_date_sk = d.d_date_sk
            LIMIT 1
        ) wp_l (wp_url) ON TRUE
        LEFT JOIN LATERAL (
            SELECT ws.web_name
            FROM web_site ws
            WHERE ws.web_open_date_sk = d.d_date_sk
            LIMIT 1
        ) ws_l (web_name) ON TRUE
        WHERE d.d_year BETWEEN 2000 AND 2002
          AND i.i_current_price BETWEEN 100 AND 500
          AND (w.w_gmt_offset IS NULL OR w.w_gmt_offset > -6)
          AND ib.ib_upper_bound >= 80000
    ),
    -- Aggregate sales and inventory, using ROLLUP for subtotals and a grand total
    agg AS (
        SELECT
            d_year,
            i_category,
            i_brand,
            w_state,
            hd_buy_potential,
            ib_upper_bound,
            SUM(sales_amount) AS total_sales,
            SUM(COALESCE(ir.qty_on_hand, 0)) AS total_inventory
        FROM annotated_sales a
        LEFT JOIN inv_rollup ir
          ON a.item_sk = ir.inv_item_sk
         AND a.warehouse_sk = ir.inv_warehouse_sk
        GROUP BY ROLLUP (d_year, i_category, i_brand, w_state, hd_buy_potential, ib_upper_bound)
    )
SELECT
    d_year,
    i_category,
    i_brand,
    w_state,
    hd_buy_potential,
    ib_upper_bound,
    total_sales,
    total_inventory,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100

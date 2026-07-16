WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        i.i_product_name,
        d.d_year,
        d.d_moy,
        d.d_date_sk AS sold_date_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        MAX(d.d_date) AS max_sale_date
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE i.i_category = 'Sports'
      AND d.d_year BETWEEN 2000 AND 2005
    GROUP BY cs.cs_item_sk, i.i_product_name, d.d_year, d.d_moy, d.d_date_sk
),
returns_agg AS (
    SELECT
        cr.cr_item_sk,
        d.d_year,
        d.d_moy,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_item_sk, d.d_year, d.d_moy
),
enriched_sales AS (
    SELECT
        s.cs_item_sk,
        s.i_product_name,
        s.d_year,
        s.d_moy,
        s.sold_date_sk,
        s.total_sales,
        s.total_profit,
        COALESCE(r.total_return_qty, 0) AS total_return_qty,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        CASE WHEN EXISTS (
                SELECT 1 FROM promotion p
                WHERE p.p_item_sk = s.cs_item_sk
                  AND s.sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
            ) THEN 1 ELSE 0 END AS is_promo,
        ROW_NUMBER() OVER (PARTITION BY s.cs_item_sk ORDER BY s.total_sales DESC) AS sales_rank,
        LAG(s.total_sales) OVER (PARTITION BY s.cs_item_sk ORDER BY s.d_year, s.d_moy) AS prev_month_sales
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.cs_item_sk = r.cr_item_sk
        AND s.d_year = r.d_year
        AND s.d_moy = r.d_moy
),
top_items AS (
    SELECT *
    FROM enriched_sales
    WHERE sales_rank <= 5
),
cat_final AS (
    SELECT
        CONCAT(ti.i_product_name, ' (', CAST(ti.d_year AS VARCHAR), '-', LPAD(CAST(ti.d_moy AS VARCHAR), 2, '0'), ')') AS product_month,
        ti.total_sales,
        ti.total_profit,
        ti.total_return_qty,
        ti.total_return_amount,
        ti.is_promo,
        CASE WHEN ti.total_return_qty > 0 THEN ti.total_return_amount / ti.total_return_qty ELSE 0 END AS avg_return_amount,
        ti.sales_rank,
        ti.prev_month_sales,
        ti.total_sales - COALESCE(ti.prev_month_sales, 0) AS sales_change,
        CASE 
            WHEN COALESCE(ti.prev_month_sales, 0) = 0 THEN NULL
            ELSE ((ti.total_sales - ti.prev_month_sales) / ti.prev_month_sales) * 100
        END AS sales_change_pct
    FROM top_items ti
),
web_agg AS (
    SELECT
        w.ws_item_sk,
        w.ws_sold_date_sk,
        SUM(w.ws_ext_sales_price) AS total_sales,
        SUM(w.ws_net_profit) AS total_profit,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_sales w
    LEFT JOIN web_returns wr
        ON w.ws_item_sk = wr.wr_item_sk
        AND w.ws_sold_date_sk = wr.wr_returned_date_sk
    GROUP BY w.ws_item_sk, w.ws_sold_date_sk
),
web_final AS (
    SELECT
        CONCAT('WEB: ', CAST(w.ws_item_sk AS VARCHAR)) AS product_month,
        w.total_sales,
        w.total_profit,
        COALESCE(w.total_return_qty, 0) AS total_return_qty,
        COALESCE(w.total_return_amount, 0) AS total_return_amount,
        0 AS is_promo,
        CASE WHEN COALESCE(w.total_return_qty, 0) > 0 THEN w.total_return_amount / w.total_return_qty ELSE NULL END AS avg_return_amount,
        NULL AS sales_rank,
        NULL AS prev_month_sales,
        NULL AS sales_change,
        NULL AS sales_change_pct
    FROM web_agg w
    WHERE w.total_sales > (SELECT AVG(ws_ext_sales_price) FROM web_sales)
)
SELECT *
FROM cat_final
UNION ALL
SELECT *
FROM web_final
ORDER BY total_sales DESC
LIMIT 100

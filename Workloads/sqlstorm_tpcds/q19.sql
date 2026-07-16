WITH
filtered_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 2002
),
catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        i.i_item_id,
        i.i_category,
        i.i_color,
        SUM(cs.cs_quantity) AS total_qty,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) FILTER (WHERE cs.cs_coupon_amt > 0) AS coupon_cnt,
        MAX(cs.cs_ext_sales_price) AS max_sale,
        MIN(cs.cs_ext_sales_price) AS min_sale,
        AVG(cs.cs_ext_sales_price) AS avg_sale
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM filtered_dates)
    GROUP BY cs.cs_sold_date_sk, i.i_item_id, i.i_category, i.i_color
),
store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        i.i_item_id,
        i.i_category,
        i.i_color,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) FILTER (WHERE ss.ss_coupon_amt > 0) AS coupon_cnt,
        MAX(ss.ss_ext_sales_price) AS max_sale,
        MIN(ss.ss_ext_sales_price) AS min_sale,
        AVG(ss.ss_ext_sales_price) AS avg_sale
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM filtered_dates)
    GROUP BY ss.ss_sold_date_sk, i.i_item_id, i.i_category, i.i_color
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        i.i_item_id,
        i.i_category,
        i.i_color,
        SUM(ws.ws_quantity) AS total_qty,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) FILTER (WHERE ws.ws_coupon_amt > 0) AS coupon_cnt,
        MAX(ws.ws_ext_sales_price) AS max_sale,
        MIN(ws.ws_ext_sales_price) AS min_sale,
        AVG(ws.ws_ext_sales_price) AS avg_sale
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM filtered_dates)
    GROUP BY ws.ws_sold_date_sk, i.i_item_id, i.i_category, i.i_color
),
combined_sales AS (
    SELECT *
    FROM catalog_sales_agg
    UNION ALL
    SELECT *
    FROM store_sales_agg
    UNION ALL
    SELECT *
    FROM web_sales_agg
),
returns_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        i.i_item_id,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY sr.sr_returned_date_sk, i.i_item_id

    UNION ALL

    SELECT
        cr.cr_returned_date_sk AS date_sk,
        i.i_item_id,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY cr.cr_returned_date_sk, i.i_item_id

    UNION ALL

    SELECT
        wr.wr_returned_date_sk AS date_sk,
        i.i_item_id,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY wr.wr_returned_date_sk, i.i_item_id
),
returns_total AS (
    SELECT
        date_sk,
        i_item_id,
        SUM(total_return_qty) AS total_return_qty,
        SUM(total_return_amt) AS total_return_amt
    FROM returns_agg
    GROUP BY date_sk, i_item_id
),
enriched_sales AS (
    SELECT
        cs.date_sk,
        d.d_date,
        cs.i_item_id,
        cs.i_category,
        cs.i_color,
        cs.total_qty,
        cs.total_sales,
        cs.total_profit,
        cs.coupon_cnt,
        cs.max_sale,
        cs.min_sale,
        cs.avg_sale,
        SUM(cs.total_sales) OVER (PARTITION BY cs.i_item_id ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.i_category ORDER BY cs.total_sales DESC) AS category_sales_rank,
        CASE WHEN ROW_NUMBER() OVER (PARTITION BY cs.i_category ORDER BY cs.total_sales DESC) = 1 THEN CONCAT('TOP-', cs.i_item_id) ELSE NULL END AS top_seller_flag,
        (SELECT AVG(inner_cs.total_sales) FROM catalog_sales_agg inner_cs WHERE inner_cs.i_item_id = cs.i_item_id AND inner_cs.date_sk BETWEEN cs.date_sk - 30 AND cs.date_sk) AS moving_avg_30d,
        COALESCE(cs.total_profit, 0) - COALESCE(cs.coupon_cnt * 0.5, 0) AS adjusted_profit,
        CASE WHEN ((cs.total_qty % 2 = 0) <> (cs.total_sales > 1000)) THEN 1 ELSE 0 END AS weird_predicate_flag
    FROM combined_sales cs
    LEFT JOIN date_dim d ON cs.date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    RIGHT JOIN (SELECT p.p_promo_sk FROM promotion p WHERE p.p_discount_active = 'Y') promo_active ON p.p_promo_sk = promo_active.p_promo_sk
    WHERE d.d_year = 2001
),
final_join AS (
    SELECT
        es.date_sk,
        es.d_date,
        es.i_item_id,
        es.i_category,
        es.i_color,
        es.total_qty,
        es.total_sales,
        es.adjusted_profit,
        es.running_total_sales,
        es.category_sales_rank,
        es.top_seller_flag,
        es.moving_avg_30d,
        es.weird_predicate_flag,
        rt.total_return_qty,
        rt.total_return_amt
    FROM enriched_sales es
    FULL OUTER JOIN returns_total rt
        ON es.date_sk = rt.date_sk AND es.i_item_id = rt.i_item_id
    WHERE es.category_sales_rank = 1
)
SELECT
    fj.date_sk,
    fj.d_date,
    fj.i_item_id,
    fj.i_category,
    fj.i_color,
    fj.total_qty,
    fj.total_sales,
    fj.adjusted_profit,
    fj.running_total_sales,
    fj.category_sales_rank,
    COALESCE(fj.top_seller_flag, 'N/A') AS top_seller_flag,
    ROUND(fj.moving_avg_30d, 2) AS moving_avg_30d,
    fj.weird_predicate_flag,
    CASE
        WHEN fj.i_color IS NULL THEN 'UNKNOWN_COLOR'
        WHEN strpos(UPPER(fj.i_color), 'RED') > 0 THEN REPLACE(UPPER(fj.i_color), 'RED', 'R')
        ELSE TRIM(fj.i_color)
    END AS normalized_color,
    TRY_CAST(substr(fj.i_item_id, 1, 5) AS INTEGER) AS item_id_prefix_int,
    fj.total_return_qty,
    fj.total_return_amt
FROM final_join fj
ORDER BY fj.total_sales DESC
LIMIT 100

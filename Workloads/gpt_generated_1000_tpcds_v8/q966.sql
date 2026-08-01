WITH
    /* Stores that had sales in 2001 */
    stores_in_sales AS (
        SELECT DISTINCT s.s_store_id
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    /* Stores that had returns in 2001 */
    stores_in_returns AS (
        SELECT DISTINCT s.s_store_id
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    /* Stores appearing in BOTH sales and returns */
    common_stores AS (
        SELECT s_store_id FROM stores_in_sales
        INTERSECT
        SELECT s_store_id FROM stores_in_returns
    ),

    /* Aggregated sales per store / year / promotion */
    sales_agg AS (
        SELECT
            d.d_year,
            s.s_store_id,
            p.p_promo_name,
            COUNT(*) AS sales_cnt,
            SUM(ss.ss_net_profit) AS total_net_profit,
            AVG(ss.ss_quantity) AS avg_qty,
            MAX(ss.ss_ext_tax) AS max_tax,
            CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
        FROM store_sales ss
        JOIN date_dim d            ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s               ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_year = 2001
          AND s.s_state = 'CA'
          AND p.p_channel_email = 'Y'
          AND cd.cd_education_status = 'College'
        GROUP BY d.d_year, s.s_store_id, p.p_promo_name
    ),

    /* Aggregated returns per store / year */
    returns_agg AS (
        SELECT
            d.d_year,
            s.s_store_id,
            COUNT(*) AS return_cnt,
            SUM(sr.sr_net_loss) AS total_net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN store s    ON sr.sr_store_sk = s.s_store_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_year = 2001
          AND s.s_state = 'CA'
          AND cd.cd_gender = 'M'
        GROUP BY d.d_year, s.s_store_id
    ),

    /* Aggregated catalog returns per year / department */
    catalog_ret_agg AS (
        SELECT
            d.d_year,
            cp.cp_department,
            COUNT(*) AS catalog_return_cnt,
            SUM(cr.cr_net_loss) AS total_catalog_loss
        FROM catalog_returns cr
        JOIN date_dim d          ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN catalog_page cp     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE d.d_year = 2001
          AND cp.cp_department = 'Electronics'
          AND sm.sm_type = 'AIR'
        GROUP BY d.d_year, cp.cp_department
    ),

    /* Ranking of stores by total profit (window function) */
    sales_rank AS (
        SELECT
            s.s_store_id,
            d.d_year,
            SUM(ss.ss_net_profit) AS store_profit,
            ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY s.s_store_id, d.d_year
    ),

    /* Union of sales profit and returns loss per store / year */
    union_sales_returns AS (
        SELECT
            s.s_store_id,
            d.d_year,
            SUM(ss.ss_net_profit) AS profit,
            'sales' AS source
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY s.s_store_id, d.d_year
        UNION
        SELECT
            s.s_store_id,
            d.d_year,
            -SUM(sr.sr_net_loss) AS profit,
            'returns' AS source
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY s.s_store_id, d.d_year
    ),

    /* Full outer join between sales aggregation and catalog‑return aggregation */
    full_agg AS (
        SELECT
            sa.d_year,
            sa.s_store_id,
            sa.sales_cnt,
            sa.total_net_profit,
            cr.catalog_return_cnt,
            cr.total_catalog_loss
        FROM sales_agg sa
        FULL OUTER JOIN catalog_ret_agg cr
            ON sa.d_year = cr.d_year
    )
SELECT
    f.d_year,
    f.s_store_id,
    f.sales_cnt,
    f.total_net_profit,
    f.catalog_return_cnt,
    f.total_catalog_loss,
    cs.profit_category,
    sr.return_cnt,
    sr.total_net_loss,
    rk.profit_rank,
    CASE WHEN f.total_net_profit IS NULL THEN 0 ELSE f.total_net_profit END -
        COALESCE(sr.total_net_loss, 0) AS net_margin,
    (SELECT COUNT(*) FROM union_sales_returns us WHERE us.s_store_id = f.s_store_id) AS union_record_cnt
FROM full_agg f
LEFT JOIN returns_agg sr   ON f.s_store_id = sr.s_store_id AND f.d_year = sr.d_year
LEFT JOIN sales_agg cs     ON f.s_store_id = cs.s_store_id AND f.d_year = cs.d_year
LEFT JOIN sales_rank rk    ON f.s_store_id = rk.s_store_id AND f.d_year = rk.d_year
WHERE f.s_store_id IN (SELECT s_store_id FROM common_stores)
  AND (f.total_net_profit > 5000 OR f.catalog_return_cnt > 0)
ORDER BY net_margin DESC
LIMIT 100

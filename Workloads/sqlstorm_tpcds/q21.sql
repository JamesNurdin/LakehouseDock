WITH
    sales_agg AS (
        SELECT
            ss.ss_store_sk AS entity_sk,
            'store' AS entity_type,
            CAST(date_trunc('month', dd.d_date) AS DATE) AS month_date,
            SUM(ss.ss_net_profit) AS net_profit,
            SUM(ss.ss_quantity) AS total_quantity,
            COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
            MAX(ss.ss_net_paid) AS max_net_paid,
            MIN(ss.ss_net_paid) AS min_net_paid,
            CONCAT('Store_', COALESCE(s.s_store_name, 'UNKNOWN')) AS entity_name,
            CASE
                WHEN SUM(ss.ss_ext_sales_price) = 0 THEN NULL
                ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
            END AS profit_margin
        FROM store_sales ss
        LEFT JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
        LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE dd.d_year = 2000
        GROUP BY ss.ss_store_sk, s.s_store_name, CAST(date_trunc('month', dd.d_date) AS DATE)
    ),
    catalog_agg AS (
        SELECT
            cs.cs_catalog_page_sk AS entity_sk,
            'catalog' AS entity_type,
            CAST(date_trunc('month', dd.d_date) AS DATE) AS month_date,
            SUM(cs.cs_net_profit) AS net_profit,
            SUM(cs.cs_quantity) AS total_quantity,
            COUNT(DISTINCT cs.cs_order_number) AS distinct_tickets,
            MAX(cs.cs_net_paid) AS max_net_paid,
            MIN(cs.cs_net_paid) AS min_net_paid,
            CONCAT('CatalogPage_', COALESCE(cp.cp_description, 'NONE')) AS entity_name,
            CASE
                WHEN SUM(cs.cs_ext_sales_price) = 0 THEN NULL
                ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_ext_sales_price)
            END AS profit_margin
        FROM catalog_sales cs
        LEFT JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
        LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE dd.d_year = 2000
        GROUP BY cs.cs_catalog_page_sk, cp.cp_description, CAST(date_trunc('month', dd.d_date) AS DATE)
    ),
    web_agg AS (
        SELECT
            ws.ws_web_page_sk AS entity_sk,
            'web' AS entity_type,
            CAST(date_trunc('month', dd.d_date) AS DATE) AS month_date,
            SUM(ws.ws_net_profit) AS net_profit,
            SUM(ws.ws_quantity) AS total_quantity,
            COUNT(DISTINCT ws.ws_order_number) AS distinct_tickets,
            MAX(ws.ws_net_paid) AS max_net_paid,
            MIN(ws.ws_net_paid) AS min_net_paid,
            CONCAT('WebPage_', COALESCE(wp.wp_url, 'NOURL')) AS entity_name,
            CASE
                WHEN SUM(ws.ws_ext_sales_price) = 0 THEN NULL
                ELSE SUM(ws.ws_net_profit) / SUM(ws.ws_ext_sales_price)
            END AS profit_margin
        FROM web_sales ws
        LEFT JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE dd.d_year = 2000
        GROUP BY ws.ws_web_page_sk, wp.wp_url, CAST(date_trunc('month', dd.d_date) AS DATE)
    ),
    union_sales AS (
        SELECT * FROM sales_agg
        UNION ALL
        SELECT * FROM catalog_agg
        UNION ALL
        SELECT * FROM web_agg
    ),
    returns_agg AS (
        SELECT
            r.entity_sk,
            r.entity_type,
            CAST(date_trunc('month', rd.d_date) AS DATE) AS month_date,
            SUM(r.return_loss) AS total_return_loss,
            SUM(r.return_quantity) AS total_return_quantity
        FROM (
            SELECT
                ss.ss_store_sk AS entity_sk,
                'store' AS entity_type,
                sr.sr_return_quantity AS return_quantity,
                sr.sr_net_loss AS return_loss,
                sr.sr_returned_date_sk AS return_date_sk
            FROM store_returns sr
            LEFT JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
            UNION ALL
            SELECT
                cs.cs_catalog_page_sk,
                'catalog',
                cr.cr_return_quantity,
                cr.cr_net_loss,
                cr.cr_returned_date_sk
            FROM catalog_returns cr
            LEFT JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
            UNION ALL
            SELECT
                ws.ws_web_page_sk,
                'web',
                wr.wr_return_quantity,
                wr.wr_net_loss,
                wr.wr_returned_date_sk
            FROM web_returns wr
            LEFT JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        ) r
        LEFT JOIN date_dim rd ON r.return_date_sk = rd.d_date_sk
        WHERE rd.d_year = 2000
        GROUP BY r.entity_sk, r.entity_type, CAST(date_trunc('month', rd.d_date) AS DATE)
    ),
    combined AS (
        SELECT
            COALESCE(us.entity_sk, rt.entity_sk) AS entity_sk,
            COALESCE(us.entity_type, rt.entity_type) AS entity_type,
            COALESCE(us.month_date, rt.month_date) AS month_date,
            us.net_profit,
            us.total_quantity,
            us.distinct_tickets,
            us.max_net_paid,
            us.min_net_paid,
            us.entity_name,
            us.profit_margin,
            COALESCE(rt.total_return_loss, 0) AS total_return_loss,
            COALESCE(rt.total_return_quantity, 0) AS total_return_quantity,
            (COALESCE(us.net_profit, 0) - COALESCE(rt.total_return_loss, 0)) AS net_profit_adj,
            ROW_NUMBER() OVER (
                PARTITION BY COALESCE(us.entity_type, rt.entity_type)
                ORDER BY (COALESCE(us.net_profit, 0) - COALESCE(rt.total_return_loss, 0)) DESC
            ) AS rank_by_adj_profit,
            CASE
                WHEN us.profit_margin IS NULL THEN CONCAT('MARGIN_NULL_', COALESCE(us.entity_type, rt.entity_type))
                WHEN us.profit_margin > 0.2 THEN CONCAT('HIGH_', COALESCE(us.entity_name, 'UNKNOWN'))
                ELSE CONCAT('LOW_', COALESCE(us.entity_name, 'UNKNOWN'))
            END AS margin_category,
            (SELECT MAX(p.net_profit)
               FROM union_sales p
               WHERE p.entity_sk = COALESCE(us.entity_sk, rt.entity_sk)
                 AND p.entity_type = COALESCE(us.entity_type, rt.entity_type)
                 AND p.month_date < COALESCE(us.month_date, rt.month_date)
            ) AS prior_max_profit,
            CASE
                WHEN COALESCE(us.entity_name, '') IS NOT DISTINCT FROM 'Store_Unknown' THEN 1
                ELSE 0
            END AS is_unknown_store
        FROM union_sales us
        FULL OUTER JOIN returns_agg rt
          ON us.entity_sk = rt.entity_sk
         AND us.entity_type = rt.entity_type
         AND us.month_date = rt.month_date
    ),
    filtered AS (
        SELECT * FROM combined
        EXCEPT
        SELECT * FROM combined WHERE profit_margin IS NULL
    ),
    final_ranked AS (
        SELECT *
        FROM filtered
        WHERE rank_by_adj_profit <= 10
    )
SELECT
    entity_type,
    entity_name,
    month_date,
    net_profit_adj,
    profit_margin,
    total_return_loss,
    margin_category,
    prior_max_profit,
    is_unknown_store,
    rank_by_adj_profit,
    CASE
        WHEN total_quantity = 0 THEN NULL
        ELSE net_profit_adj / total_quantity
    END AS profit_per_item
FROM final_ranked
WHERE
    (total_return_quantity = 0 OR total_return_quantity IS NULL)
    AND (entity_type = 'store' AND entity_name LIKE '%Store%')
    AND REGEXP_LIKE(margin_category, '^HIGH_|^LOW_')
    AND DATE_ADD('month', 12, month_date) > DATE '2024-10-01'
ORDER BY rank_by_adj_profit, net_profit_adj DESC

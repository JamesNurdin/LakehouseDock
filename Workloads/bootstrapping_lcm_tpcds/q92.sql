WITH sales_agg AS (
    SELECT
        d_sales.d_year,
        d_sales.d_month_seq,
        s.s_store_id,
        s.s_market_desc,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_tax) AS avg_ext_tax,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    GROUP BY
        d_sales.d_year,
        d_sales.d_month_seq,
        s.s_store_id,
        s.s_market_desc
),
page_creation_agg AS (
    SELECT
        d_creation.d_year,
        d_creation.d_month_seq,
        COUNT(DISTINCT wp.wp_web_page_sk) AS pages_created
    FROM web_page wp
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    GROUP BY
        d_creation.d_year,
        d_creation.d_month_seq
),
page_access_agg AS (
    SELECT
        d_access.d_year,
        d_access.d_month_seq,
        COUNT(DISTINCT wp.wp_web_page_sk) AS pages_accessed
    FROM web_page wp
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    GROUP BY
        d_access.d_year,
        d_access.d_month_seq
),
site_open_agg AS (
    SELECT
        d_open.d_year,
        d_open.d_month_seq,
        COUNT(DISTINCT ws.web_site_sk) AS sites_opened
    FROM web_site ws
    JOIN date_dim d_open
        ON ws.web_open_date_sk = d_open.d_date_sk
    GROUP BY
        d_open.d_year,
        d_open.d_month_seq
),
site_close_agg AS (
    SELECT
        d_close.d_year,
        d_close.d_month_seq,
        COUNT(DISTINCT ws.web_site_sk) AS sites_closed
    FROM web_site ws
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    GROUP BY
        d_close.d_year,
        d_close.d_month_seq
),
store_closed_agg AS (
    SELECT
        d_closed.d_year,
        d_closed.d_month_seq,
        COUNT(DISTINCT s.s_store_sk) AS stores_closed
    FROM store s
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    GROUP BY
        d_closed.d_year,
        d_closed.d_month_seq
)
SELECT
    sa.d_year,
    sa.d_month_seq,
    sa.s_store_id,
    sa.s_market_desc,
    sa.total_net_profit,
    sa.avg_ext_tax,
    sa.num_tickets,
    COALESCE(pc.pages_created, 0)      AS pages_created,
    COALESCE(pa.pages_accessed, 0)     AS pages_accessed,
    COALESCE(so.sites_opened, 0)       AS sites_opened,
    COALESCE(sc.sites_closed, 0)       AS sites_closed,
    COALESCE(stc.stores_closed, 0)     AS stores_closed
FROM sales_agg sa
LEFT JOIN page_creation_agg pc
    ON pc.d_year = sa.d_year AND pc.d_month_seq = sa.d_month_seq
LEFT JOIN page_access_agg pa
    ON pa.d_year = sa.d_year AND pa.d_month_seq = sa.d_month_seq
LEFT JOIN site_open_agg so
    ON so.d_year = sa.d_year AND so.d_month_seq = sa.d_month_seq
LEFT JOIN site_close_agg sc
    ON sc.d_year = sa.d_year AND sc.d_month_seq = sa.d_month_seq
LEFT JOIN store_closed_agg stc
    ON stc.d_year = sa.d_year AND stc.d_month_seq = sa.d_month_seq
ORDER BY sa.total_net_profit DESC
LIMIT 100

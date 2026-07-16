WITH
sales_sold AS (
    SELECT
        cs_sold_date_sk AS d_date_sk,
        SUM(cs_net_paid) AS total_sales_net_paid,
        SUM(cs_net_profit) AS total_sales_net_profit,
        SUM(cs_ext_sales_price) AS total_sales_ext_price,
        COUNT(DISTINCT cs_item_sk) AS distinct_items_sold
    FROM catalog_sales
    GROUP BY cs_sold_date_sk
),
sales_ship AS (
    SELECT
        cs_ship_date_sk AS d_date_sk,
        SUM(cs_net_paid) AS total_shipped_net_paid,
        SUM(cs_ext_sales_price) AS total_shipped_ext_price,
        COUNT(*) AS shipped_sales_cnt
    FROM catalog_sales
    GROUP BY cs_ship_date_sk
),
returns_by_date AS (
    SELECT
        sr_returned_date_sk AS d_date_sk,
        SUM(sr_net_loss) AS total_returns_net_loss,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_returned_date_sk
),
returns_by_store AS (
    SELECT
        sr.sr_returned_date_sk AS d_date_sk,
        s.s_store_id,
        s.s_store_name,
        SUM(sr.sr_net_loss) AS store_returns_net_loss,
        COUNT(*) AS store_returns_cnt
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    GROUP BY sr.sr_returned_date_sk, s.s_store_id, s.s_store_name
),
store_closed AS (
    SELECT
        s_closed_date_sk AS d_date_sk,
        COUNT(DISTINCT s_store_id) AS stores_closed
    FROM store
    GROUP BY s_closed_date_sk
),
wp_creation AS (
    SELECT
        wp_creation_date_sk AS d_date_sk,
        SUM(wp_image_count) AS total_image_count,
        COUNT(DISTINCT wp_web_page_id) AS total_pages_created
    FROM web_page
    GROUP BY wp_creation_date_sk
),
wp_access AS (
    SELECT
        wp_access_date_sk AS d_date_sk,
        SUM(wp_link_count) AS total_link_count,
        COUNT(DISTINCT wp_web_page_id) AS total_pages_accessed
    FROM web_page
    GROUP BY wp_access_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    COALESCE(ss.total_sales_net_paid, 0) AS total_sales_net_paid,
    COALESCE(ss.total_sales_net_profit, 0) AS total_sales_net_profit,
    COALESCE(ss.distinct_items_sold, 0) AS distinct_items_sold,
    COALESCE(sh.total_shipped_net_paid, 0) AS total_shipped_net_paid,
    COALESCE(sh.shipped_sales_cnt, 0) AS shipped_sales_cnt,
    COALESCE(rbd.total_returns_net_loss, 0) AS total_returns_net_loss,
    COALESCE(rbd.total_returns, 0) AS total_returns,
    COALESCE(sc.stores_closed, 0) AS stores_closed,
    COALESCE(wc.total_image_count, 0) AS total_image_count,
    COALESCE(wc.total_pages_created, 0) AS total_pages_created,
    COALESCE(wa.total_link_count, 0) AS total_link_count,
    COALESCE(wa.total_pages_accessed, 0) AS total_pages_accessed,
    COALESCE(ss.total_sales_net_paid, 0) - COALESCE(rbd.total_returns_net_loss, 0) AS net_revenue,
    rs.s_store_id,
    rs.s_store_name,
    COALESCE(rs.store_returns_net_loss, 0) AS store_returns_net_loss,
    COALESCE(rs.store_returns_cnt, 0) AS store_returns_cnt
FROM date_dim d
LEFT JOIN sales_sold ss
    ON ss.d_date_sk = d.d_date_sk
LEFT JOIN sales_ship sh
    ON sh.d_date_sk = d.d_date_sk
LEFT JOIN returns_by_date rbd
    ON rbd.d_date_sk = d.d_date_sk
LEFT JOIN store_closed sc
    ON sc.d_date_sk = d.d_date_sk
LEFT JOIN wp_creation wc
    ON wc.d_date_sk = d.d_date_sk
LEFT JOIN wp_access wa
    ON wa.d_date_sk = d.d_date_sk
LEFT JOIN returns_by_store rs
    ON rs.d_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2023
ORDER BY net_revenue DESC
LIMIT 100

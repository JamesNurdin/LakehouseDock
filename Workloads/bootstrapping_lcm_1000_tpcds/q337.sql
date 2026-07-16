WITH cs_sold_agg AS (
    SELECT cs_sold_date_sk AS d_date_sk,
           SUM(cs_net_profit) AS total_net_profit,
           SUM(cs_net_paid) AS total_net_paid,
           COUNT(*) AS cnt_sales
    FROM catalog_sales
    GROUP BY cs_sold_date_sk
),
cs_ship_agg AS (
    SELECT cs_ship_date_sk AS d_date_sk,
           SUM(cs_ext_ship_cost) AS total_ship_cost,
           SUM(cs_ext_tax) AS total_ship_tax,
           COUNT(*) AS cnt_ship_sales
    FROM catalog_sales
    GROUP BY cs_ship_date_sk
),
sr_agg AS (
    SELECT sr_returned_date_sk AS d_date_sk,
           sr_store_sk,
           SUM(sr_net_loss) AS total_net_loss,
           SUM(sr_return_quantity) AS total_return_qty,
           COUNT(*) AS cnt_returns
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_store_sk
),
store_closed_agg AS (
    SELECT s_closed_date_sk AS d_date_sk,
           COUNT(*) AS cnt_closed_stores,
           SUM(s_floor_space) AS total_floor_space
    FROM store
    GROUP BY s_closed_date_sk
),
wp_creation_agg AS (
    SELECT wp_creation_date_sk AS d_date_sk,
           COUNT(*) AS cnt_pages_created,
           SUM(wp_image_count) AS total_image_count,
           SUM(wp_link_count) AS total_link_count
    FROM web_page
    GROUP BY wp_creation_date_sk
),
wp_access_agg AS (
    SELECT wp_access_date_sk AS d_date_sk,
           COUNT(*) AS cnt_pages_accessed,
           SUM(wp_char_count) AS total_char_count
    FROM web_page
    GROUP BY wp_access_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    s.s_store_name,
    s.s_city,
    COALESCE(cs_sold.total_net_profit, 0) AS total_net_profit,
    COALESCE(cs_sold.total_net_paid, 0) AS total_net_paid,
    COALESCE(cs_ship.total_ship_cost, 0) AS total_ship_cost,
    COALESCE(cs_ship.total_ship_tax, 0) AS total_ship_tax,
    COALESCE(sr.total_net_loss, 0) AS total_net_loss,
    COALESCE(sr.total_return_qty, 0) AS total_return_qty,
    COALESCE(store_closed.cnt_closed_stores, 0) AS cnt_closed_stores,
    COALESCE(store_closed.total_floor_space, 0) AS total_floor_space,
    COALESCE(wp_creation.cnt_pages_created, 0) AS cnt_pages_created,
    COALESCE(wp_creation.total_image_count, 0) AS total_image_count,
    COALESCE(wp_creation.total_link_count, 0) AS total_link_count,
    COALESCE(wp_access.cnt_pages_accessed, 0) AS cnt_pages_accessed,
    COALESCE(wp_access.total_char_count, 0) AS total_char_count
FROM date_dim d
LEFT JOIN cs_sold_agg cs_sold ON cs_sold.d_date_sk = d.d_date_sk
LEFT JOIN cs_ship_agg cs_ship ON cs_ship.d_date_sk = d.d_date_sk
LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN sr_agg sr ON sr.d_date_sk = d.d_date_sk AND sr.sr_store_sk = s.s_store_sk
LEFT JOIN store_closed_agg store_closed ON store_closed.d_date_sk = d.d_date_sk
LEFT JOIN wp_creation_agg wp_creation ON wp_creation.d_date_sk = d.d_date_sk
LEFT JOIN wp_access_agg wp_access ON wp_access.d_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
ORDER BY d.d_date, s.s_store_name

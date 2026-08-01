WITH store_sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_item_id AS item_id,
        d.d_year AS d_year,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity,
        max_time.max_time AS latest_sale_time
    FROM store_sales ss
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    CROSS JOIN LATERAL (
        SELECT MAX(t2.t_time) AS max_time
        FROM store_sales ss2
        INNER JOIN time_dim t2 ON ss2.ss_sold_time_sk = t2.t_time_sk
        WHERE ss2.ss_store_sk = ss.ss_store_sk
          AND ss2.ss_item_sk = ss.ss_item_sk
          AND ss2.ss_sold_date_sk = ss.ss_sold_date_sk
    ) AS max_time(max_time)
    WHERE d.d_year = 2020
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, i.i_item_id, d.d_year, max_time.max_time
),
catalog_sales_agg AS (
    SELECT
        cp.cp_catalog_page_id AS catalog_page_id,
        i.i_item_id AS item_id,
        d.d_year AS d_year,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        max_time.max_time AS latest_sale_time
    FROM catalog_sales cs
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    CROSS JOIN LATERAL (
        SELECT MAX(t2.t_time) AS max_time
        FROM catalog_sales cs2
        INNER JOIN time_dim t2 ON cs2.cs_sold_time_sk = t2.t_time_sk
        WHERE cs2.cs_catalog_page_sk = cs.cs_catalog_page_sk
          AND cs2.cs_item_sk = cs.cs_item_sk
          AND cs2.cs_sold_date_sk = cs.cs_sold_date_sk
    ) AS max_time(max_time)
    WHERE d.d_year = 2020
      AND cp.cp_type = 'PROMO'
    GROUP BY cp.cp_catalog_page_id, i.i_item_id, d.d_year, max_time.max_time
)
SELECT
    'store'   AS source,
    store_id   AS id,
    item_id,
    d_year     AS year,
    total_net_paid,
    total_quantity,
    latest_sale_time
FROM store_sales_agg
UNION ALL
SELECT
    'catalog' AS source,
    catalog_page_id AS id,
    item_id,
    d_year     AS year,
    total_net_paid,
    total_quantity,
    latest_sale_time
FROM catalog_sales_agg
ORDER BY total_net_paid DESC
LIMIT 100

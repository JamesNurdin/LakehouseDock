WITH agg_sales AS (
    SELECT
        s.s_store_name,
        s.s_store_sk,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        sd.d_year AS sold_year,
        sd.d_month_seq AS sold_month_seq,
        shd.d_month_seq AS ship_month_seq,
        COUNT(cs.cs_order_number) AS order_count,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_quantity) AS avg_quantity,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        MAX(cs.cs_ext_tax) AS max_tax,
        MIN(wp.wp_url) FILTER (WHERE wp.wp_type = 'home') AS example_home_url
    FROM catalog_sales cs
    JOIN date_dim sd ON cs.cs_sold_date_sk = sd.d_date_sk
    JOIN date_dim shd ON cs.cs_ship_date_sk = shd.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = sd.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = sd.d_date_sk AND wp.wp_access_date_sk = sd.d_date_sk
    WHERE sd.d_year BETWEEN 2020 AND 2022
      AND cs.cs_net_paid > 0
    GROUP BY
        s.s_store_name,
        s.s_store_sk,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        sd.d_year,
        sd.d_month_seq,
        shd.d_month_seq
)
SELECT
    a.s_store_name,
    a.w_warehouse_name,
    a.sold_year,
    a.sold_month_seq,
    a.ship_month_seq,
    a.order_count,
    a.total_net_paid,
    a.avg_quantity,
    a.total_discount,
    a.max_tax,
    a.example_home_url,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_sk ORDER BY a.total_net_paid DESC) AS store_rank,
    ROW_NUMBER() OVER (PARTITION BY a.w_warehouse_sk ORDER BY a.total_net_paid DESC) AS warehouse_rank
FROM agg_sales a
ORDER BY a.total_net_paid DESC
LIMIT 100

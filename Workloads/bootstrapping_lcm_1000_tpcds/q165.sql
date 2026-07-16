WITH agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        s.s_store_name,
        s.s_state,
        d_store_closed.d_year AS store_closed_year,
        d_cc_open.d_year AS cc_open_year,
        d_cc_closed.d_year AS cc_closed_year,
        COUNT(DISTINCT s.s_store_id) AS num_stores_closed_on_sale_date,
        COUNT(DISTINCT wp.wp_web_page_id) AS num_web_pages_created_on_sale_date,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        s.s_store_name,
        s.s_state,
        d_store_closed.d_year,
        d_cc_open.d_year,
        d_cc_closed.d_year
    HAVING SUM(cs.cs_net_paid_inc_tax) > 10000
)
SELECT
    agg.cc_call_center_sk,
    agg.cc_name,
    agg.cc_city,
    agg.s_store_name,
    agg.s_state,
    agg.store_closed_year,
    agg.cc_open_year,
    agg.cc_closed_year,
    agg.num_stores_closed_on_sale_date,
    agg.num_web_pages_created_on_sale_date,
    agg.total_net_paid_inc_tax,
    agg.total_discount,
    agg.avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY agg.cc_call_center_sk ORDER BY agg.total_net_paid_inc_tax DESC) AS rn
FROM agg
ORDER BY agg.total_net_paid_inc_tax DESC
LIMIT 100

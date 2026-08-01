WITH
    /*
     * Deep join of all five tables with multiple aliases of date_dim.
     * Includes a CASE expression, window ranking, LATERAL subquery,
     * anti‑join, UNION DISTINCT, EXCEPT subtraction and a LEFT OUTER JOIN.
     */
    joined AS (
        SELECT
            cs.cs_order_number,
            cs.cs_net_paid,
            cs.cs_net_paid_inc_tax,
            cs.cs_ext_sales_price,
            cp.cp_catalog_page_number,
            cp.cp_description,
            cc.cc_name,
            cc.cc_state,
            d_sold.d_year            AS sold_year,
            d_ship.d_year            AS ship_year,
            t.t_hour,
            CASE WHEN cc.cc_state = 'CA' THEN 'West' ELSE 'Other' END AS region,
            ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY cs.cs_net_paid DESC) AS sales_rank,
            l.avg_price
        FROM catalog_sales cs
        JOIN date_dim          d_sold   ON cs.cs_sold_date_sk   = d_sold.d_date_sk
        JOIN time_dim          t        ON cs.cs_sold_time_sk   = t.t_time_sk
        JOIN date_dim          d_ship   ON cs.cs_ship_date_sk   = d_ship.d_date_sk
        JOIN call_center       cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN date_dim     d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
        JOIN date_dim          d_open   ON cc.cc_open_date_sk   = d_open.d_date_sk
        JOIN catalog_page      cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN date_dim          d_start  ON cp.cp_start_date_sk = d_start.d_date_sk
        JOIN date_dim          d_end    ON cp.cp_end_date_sk   = d_end.d_date_sk
        CROSS JOIN LATERAL (
            SELECT avg(cs2.cs_ext_sales_price) AS avg_price
            FROM catalog_sales cs2
            WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
        ) l
        WHERE d_sold.d_year IN (2001, 2002)
          AND NOT EXISTS (
                SELECT 1
                FROM catalog_page cp_block
                WHERE cp_block.cp_catalog_page_id = cp.cp_catalog_page_id
                  AND cp_block.cp_description LIKE '%exclude%'
          )
    ),
    unioned AS (
        SELECT * FROM joined WHERE sold_year = 2001
        UNION DISTINCT
        SELECT * FROM joined WHERE sold_year = 2002
    ),
    order_set_2001 AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    order_set_2002 AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
    ),
    order_set_diff AS (
        SELECT cs_order_number FROM order_set_2002
        EXCEPT
        SELECT cs_order_number FROM order_set_2001
    ),
    filtered AS (
        SELECT *
        FROM unioned u
        WHERE u.cs_order_number IN (SELECT cs_order_number FROM order_set_diff)
    )
SELECT
    filtered.region,
    filtered.sold_year,
    COUNT(DISTINCT filtered.cs_order_number)          AS orders_cnt,
    SUM(filtered.cs_net_paid)                        AS total_net_paid,
    AVG(filtered.cs_ext_sales_price)                AS avg_ext_sales,
    MAX(filtered.avg_price)                          AS max_center_avg_price,
    MAX(filtered.sales_rank)                         AS max_sales_rank
FROM filtered
GROUP BY filtered.region, filtered.sold_year
ORDER BY total_net_paid DESC
LIMIT 100

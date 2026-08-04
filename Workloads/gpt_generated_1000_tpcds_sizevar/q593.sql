WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_sk,
            ss.ss_sold_date_sk,
            MIN(ss.ss_sold_time_sk) AS min_sold_time_sk,
            SUM(ss.ss_net_paid)      AS total_net_paid,
            SUM(ss.ss_quantity)      AS total_quantity
        FROM store_sales ss
        GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
    ),
    max_ext_sales AS (
        SELECT MAX(cs.cs_ext_sales_price) AS max_ext_sales
        FROM catalog_sales cs
    ),
    order_intersect AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        INTERSECT
        SELECT ws.ws_order_number
        FROM web_sales ws
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    d1.d_year,
    p.p_promo_name,
    ssagg.total_net_paid,
    cs.cs_ext_sales_price,
    ws.ws_net_paid,
    wr.wr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ssagg.total_net_paid DESC) AS store_rank,
    lt.sales_cnt,
    CASE WHEN ws.ws_net_paid > (SELECT max_ext_sales FROM max_ext_sales) THEN 1 ELSE 0 END AS high_net_paid_flag,
    oi.cs_order_number AS intersect_order_number
FROM
    store_sales_agg ssagg
    JOIN store s
        ON ssagg.ss_store_sk = s.s_store_sk
    JOIN date_dim d1
        ON ssagg.ss_sold_date_sk = d1.d_date_sk
    FULL OUTER JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d1.d_date_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d1.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d1.d_date_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN time_dim td
        ON ssagg.min_sold_time_sk = td.t_time_sk
    LEFT JOIN LATERAL (
        SELECT COUNT(*) AS sales_cnt
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
    ) lt ON TRUE
    LEFT JOIN order_intersect oi
        ON oi.cs_order_number = cs.cs_order_number
WHERE
    d1.d_year = 2001
ORDER BY
    s.s_store_id,
    ssagg.total_net_paid DESC
LIMIT 100

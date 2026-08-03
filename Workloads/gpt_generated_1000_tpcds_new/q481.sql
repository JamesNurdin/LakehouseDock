WITH ss_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_store_sk,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_store_sk
),
joined AS (
    SELECT
        d_sold.d_year,
        p.p_promo_name,
        CASE WHEN p.p_discount_active = 'Y' THEN cs.cs_ext_sales_price * 0.9 ELSE cs.cs_ext_sales_price END AS adjusted_sales,
        ss_agg.total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY ss_agg.total_net_paid DESC) AS rn,
        cc.cc_name,
        ws.ws_quantity AS web_qty,
        sr.sr_return_quantity
    FROM ss_agg
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = ss_agg.ss_sold_date_sk
       AND ss.ss_store_sk = ss_agg.ss_store_sk
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
       AND ws.ws_sold_time_sk = t_sold.t_time_sk
       AND ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr_ex
        WHERE cr_ex.cr_order_number = cs.cs_order_number
          AND cr_ex.cr_item_sk = cs.cs_item_sk
    )
)
SELECT d_year, p_promo_name, adjusted_sales, total_net_paid, rn
FROM joined
EXCEPT
SELECT d_year, p_promo_name, adjusted_sales, total_net_paid, rn
FROM joined
WHERE d_year = 1998
ORDER BY total_net_paid DESC
LIMIT 100

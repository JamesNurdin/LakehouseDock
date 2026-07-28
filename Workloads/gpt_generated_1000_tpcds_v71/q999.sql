WITH ss_agg AS (
    SELECT ss_customer_sk,
           ss_sold_date_sk,
           SUM(ss_net_paid)   AS ss_total_paid,
           SUM(ss_net_profit) AS ss_total_profit
    FROM store_sales
    WHERE ss_coupon_amt > 0
    GROUP BY ss_customer_sk, ss_sold_date_sk
),

avg_sales_profit AS (
    SELECT AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
)

SELECT *
FROM (
    -- 1️⃣  Call‑center based branch
    SELECT
        cc.cc_call_center_id                     AS group_key,
        'call_center'                            AS src,
        SUM(cs.cs_net_profit)                    AS profit,
        c.c_customer_id,
        c.c_birth_year,
        w.w_warehouse_name,
        t.t_hour,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY SUM(cs.cs_net_profit) DESC) AS rn,
        (SELECT COUNT(DISTINCT wp2.wp_web_page_id)
         FROM web_page wp2
         WHERE wp2.wp_customer_sk = c.c_customer_sk)                     AS distinct_pages,
        (SELECT avg_profit FROM avg_sales_profit)                           AS avg_sales_profit
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk      = cr.cr_item_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
     AND wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN ss_agg sa
      ON sa.ss_customer_sk = c.c_customer_sk
     AND sa.ss_sold_date_sk = cs.cs_sold_date_sk
    WHERE cc.cc_state = 'CA'
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND w.w_state = 'TX'
      AND t.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_quantity > 0
      AND ws.ws_net_profit > 0
    GROUP BY cc.cc_call_center_id,
             c.c_customer_id,
             c.c_birth_year,
             w.w_warehouse_name,
             t.t_hour,
             c.c_customer_sk

    UNION ALL

    -- 2️⃣  Reason based branch
    SELECT
        r.r_reason_desc                          AS group_key,
        'reason'                                 AS src,
        SUM(-cr.cr_net_loss)                     AS profit,
        c.c_customer_id,
        c.c_birth_year,
        w.w_warehouse_name,
        t.t_hour,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY SUM(-cr.cr_net_loss) DESC) AS rn,
        (SELECT COUNT(DISTINCT wp2.wp_web_page_id)
         FROM web_page wp2
         WHERE wp2.wp_customer_sk = c.c_customer_sk)                     AS distinct_pages,
        (SELECT avg_profit FROM avg_sales_profit)                           AS avg_sales_profit
    FROM catalog_returns cr
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
     AND wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN ss_agg sa
      ON sa.ss_customer_sk = c.c_customer_sk
     AND sa.ss_sold_date_sk = cr.cr_returned_date_sk
    WHERE r.r_reason_desc IS NOT NULL
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND w.w_state = 'TX'
      AND t.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_quantity > 0
      AND ws.ws_net_profit > 0
    GROUP BY r.r_reason_desc,
             c.c_customer_id,
             c.c_birth_year,
             w.w_warehouse_name,
             t.t_hour,
             c.c_customer_sk
) final_result
ORDER BY profit DESC, rn
LIMIT 100

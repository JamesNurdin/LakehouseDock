WITH joined_data AS (
    -- first branch of the UNION – filters on CA and high price
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        i.i_item_id,
        i.i_current_price,
        i.i_color,
        cc.cc_name AS call_center_name,
        w.w_city AS warehouse_city,
        r.r_reason_desc,
        ss.ss_net_paid AS store_net_paid,
        ws.ws_net_paid AS web_net_paid,
        sr.sr_fee,
        ARRAY[ 'X', 'Y', 'Z' ] AS extra_vals,
        1 AS branch_id
    FROM catalog_returns cr
    JOIN item i                     ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c                 ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd   ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc             ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w                ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r                   ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr      ON sr.sr_item_sk = i.i_item_sk
                                   AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_sales ws          ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_current_price > 50
      AND cc.cc_state = 'CA'
      AND w.w_city = 'Seattle'
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND r.r_reason_desc LIKE '%defect%'
      AND cd.cd_gender = 'M'
),
joined_data_alt AS (
    -- second branch of the UNION – different geographic and price predicates
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        i.i_item_id,
        i.i_current_price,
        i.i_color,
        cc.cc_name AS call_center_name,
        w.w_city AS warehouse_city,
        r.r_reason_desc,
        ss.ss_net_paid AS store_net_paid,
        ws.ws_net_paid AS web_net_paid,
        sr.sr_fee,
        ARRAY[ 'A', 'B', 'C' ] AS extra_vals,
        2 AS branch_id
    FROM catalog_returns cr
    JOIN item i                     ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c                 ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd   ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc             ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w                ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r                   ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr      ON sr.sr_item_sk = i.i_item_sk
                                   AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_sales ws          ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_current_price BETWEEN 20 AND 100
      AND cc.cc_state = 'TX'
      AND w.w_city = 'Dallas'
      AND cr.cr_returned_date_sk BETWEEN 2450200 AND 2450300
      AND r.r_reason_desc LIKE '%damage%'
      AND cd.cd_gender = 'F'
),
combined AS (
    SELECT * FROM joined_data
    UNION DISTINCT
    SELECT * FROM joined_data_alt
),
filtered AS (
    SELECT
        cj.c_customer_id,
        cj.customer_name,
        cj.i_item_id,
        cj.i_current_price,
        cj.i_color,
        cj.call_center_name,
        cj.warehouse_city,
        cj.r_reason_desc,
        COALESCE(cj.store_net_paid, 0) + COALESCE(cj.web_net_paid, 0) AS total_net_paid,
        cj.sr_fee,
        val
    FROM combined cj
    -- expand the array column per row
    CROSS JOIN UNNEST(cj.extra_vals) AS t(val)
    -- exclude customers that appear in a high‑fee store_return
    WHERE cj.c_customer_id NOT IN (
        SELECT DISTINCT c2.c_customer_id
        FROM store_returns sr2
        JOIN customer c2 ON sr2.sr_customer_sk = c2.c_customer_sk
        WHERE sr2.sr_fee > 70
    )
    -- additional ad‑hoc predicates to reach at least six filters
    AND cj.i_color IN ('Red', 'Blue')
    AND cj.call_center_name LIKE 'A%'
    AND cj.warehouse_city <> 'New York'
),
ranked AS (
    SELECT
        f.*, 
        RANK() OVER (ORDER BY f.total_net_paid DESC) AS sales_rank,
        ROW_NUMBER() OVER (PARTITION BY f.c_customer_id ORDER BY f.sr_fee DESC) AS fee_row_num,
        CASE WHEN f.i_current_price > 200 THEN 1 ELSE 0 END AS high_price_flag
    FROM filtered f
)
SELECT DISTINCT
    r.c_customer_id,
    r.customer_name,
    r.i_item_id,
    r.i_current_price,
    r.i_color,
    r.call_center_name,
    r.warehouse_city,
    r.r_reason_desc,
    r.total_net_paid,
    r.sales_rank,
    r.high_price_flag,
    r.val AS extra_value
FROM ranked r
ORDER BY r.sales_rank ASC, r.c_customer_id
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY

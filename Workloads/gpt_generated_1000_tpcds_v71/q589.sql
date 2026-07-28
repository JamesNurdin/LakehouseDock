WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        p.p_promo_id,
        p.p_channel_email,
        p.p_channel_radio,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ca.ca_state,
        w.w_warehouse_id,
        w.w_warehouse_sq_ft,
        ss.ss_net_paid AS ss_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        cr.cr_return_amount AS cr_return_amount
    FROM catalog_returns cr
    JOIN item i                     ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w                ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p                ON p.p_item_sk = i.i_item_sk
    JOIN customer c                 ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd   ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sales ss        ON ss.ss_item_sk = i.i_item_sk AND ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws          ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = c.c_customer_sk
),
agg AS (
    SELECT
        i_category,
        p_channel_email,
        SUM(COALESCE(ss_net_paid, 0) + COALESCE(ws_net_paid, 0) - COALESCE(cr_return_amount, 0)) AS total_revenue,
        COUNT(DISTINCT i_item_id) AS uniq_items_sold
    FROM base
    WHERE w_warehouse_sq_ft > 800000
      AND cd_purchase_estimate >= 2000
      AND p_channel_email = 'N'
      AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_item_sk = base.i_item_sk
              AND p2.p_channel_radio = 'N'
        )
    GROUP BY GROUPING SETS (
        (i_category, p_channel_email),
        (i_category),
        ()
    )
    HAVING SUM(COALESCE(ss_net_paid, 0) + COALESCE(ws_net_paid, 0) - COALESCE(cr_return_amount, 0)) > 10000
)
SELECT
    i_category,
    p_channel_email,
    total_revenue,
    uniq_items_sold,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY revenue_rank
LIMIT 100

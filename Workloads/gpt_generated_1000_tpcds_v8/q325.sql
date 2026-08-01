WITH ss_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS total_transactions,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND i.i_color = 'BLUE'
    GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk, ss.ss_store_sk
)
SELECT
    s.s_store_id,
    i.i_item_id,
    cp.cp_catalog_number,
    d2.d_date,
    ss_agg.total_net_paid,
    ss_agg.total_transactions,
    ss_agg.avg_quantity,
    p.p_promo_id,
    r.r_reason_desc,
    sm.sm_type,
    w.w_warehouse_name,
    inv.inv_quantity_on_hand,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr3
        WHERE cr3.cr_item_sk = i.i_item_sk
          AND cr3.cr_returned_date_sk = d2.d_date_sk
    ) AS returns_count,
    (
        SELECT MAX(p_sub.p_cost)
        FROM promotion p_sub
        WHERE p_sub.p_item_sk = i.i_item_sk
    ) AS max_promo_cost,
    RANK() OVER (ORDER BY ss_agg.total_net_paid DESC) AS net_paid_rank
FROM ss_agg
RIGHT OUTER JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN item i ON ss_agg.ss_item_sk = i.i_item_sk
JOIN date_dim d2 ON ss_agg.ss_sold_date_sk = d2.d_date_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
FULL OUTER JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
FULL OUTER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN (
    SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
) inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d2.d_date_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d2.d_date_sk
WHERE p.p_channel_dmail = 'Y'
  AND cp.cp_catalog_number IN (14, 18)
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_returned_date_sk = d2.d_date_sk
    )
ORDER BY ss_agg.total_net_paid DESC
LIMIT 100

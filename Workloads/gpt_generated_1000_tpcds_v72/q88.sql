WITH reason_union AS (
    SELECT r_reason_sk, r_reason_desc FROM reason
    UNION
    SELECT cr.cr_reason_sk AS r_reason_sk, r.r_reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
)
,
base_agg AS (
    SELECT
        d.d_year,
        c.c_customer_id,
        c.c_customer_sk,
        s.s_store_name,
        s.s_store_sk,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        cp.cp_description,
        cp.cp_catalog_number,
        sm.sm_type,
        SUM(cs.cs_net_paid)                               AS total_net_paid,
        SUM(cs.cs_quantity)                               AS total_quantity,
        COUNT(DISTINCT cs.cs_item_sk)                    AS distinct_items,
        COUNT(DISTINCT i.inv_item_sk)                    AS inventory_item_cnt,
        COUNT(DISTINCT cr.cr_reason_sk)                  AS distinct_reason_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                           AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_store_sk = sr.sr_store_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
                     AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                             AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason ru ON ru.r_reason_sk = cr.cr_reason_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
                         AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND cp.cp_catalog_number IN (10, 12)
        AND hd.hd_income_band_sk = 12
        AND s.s_state = 'CA'
        AND sm.sm_type = 'AIR'
        AND EXISTS (
            SELECT 1 FROM store_returns sr2
            WHERE sr2.sr_store_sk = s.s_store_sk
              AND sr2.sr_return_quantity > 5
        )
    GROUP BY
        d.d_year,
        c.c_customer_id,
        c.c_customer_sk,
        s.s_store_name,
        s.s_store_sk,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        cp.cp_description,
        cp.cp_catalog_number,
        sm.sm_type
)
SELECT
    d_year,
    c_customer_id,
    s_store_name,
    w_warehouse_name,
    cp_description,
    total_net_paid,
    total_quantity,
    distinct_items,
    inventory_item_cnt,
    distinct_reason_cnt,
    CASE
        WHEN total_net_paid > 20000 THEN 'PLATINUM'
        WHEN total_net_paid > 10000 THEN 'GOLD'
        ELSE 'SILVER'
    END AS tier,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS revenue_rank,
    (SELECT AVG(cs2.cs_net_paid)
     FROM catalog_sales cs2
     WHERE cs2.cs_bill_customer_sk = c_customer_sk) AS avg_customer_net_paid,
    SUM(total_net_paid) OVER (
        PARTITION BY d_year
        ORDER BY total_net_paid DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_year_net
FROM base_agg
ORDER BY total_net_paid DESC
LIMIT 100

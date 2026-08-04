WITH sampled_inventory AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),

store_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_profit,
        i1.i_item_id,
        i1.i_category,
        p.p_promo_id,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY ss.ss_net_profit DESC) AS promo_rank
    FROM store_sales ss
    JOIN time_dim td               ON ss.ss_sold_time_sk   = td.t_time_sk
    JOIN item i1                   ON ss.ss_item_sk        = i1.i_item_sk
    JOIN promotion p               ON ss.ss_promo_sk       = p.p_promo_sk
    JOIN customer c                ON ss.ss_customer_sk    = c.c_customer_sk
    JOIN customer_address ca       ON ss.ss_addr_sk        = ca.ca_address_sk
    WHERE EXISTS (
        SELECT 1
        FROM sampled_inventory si
        WHERE si.inv_item_sk = ss.ss_item_sk
          AND si.inv_quantity_on_hand > 0
    )
),

order_numbers_without_return AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
),

catalog_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        i2.i_item_id,
        p2.p_promo_id,
        ROW_NUMBER() OVER (PARTITION BY p2.p_promo_id ORDER BY cs.cs_net_profit DESC) AS promo_rank
    FROM catalog_sales cs
    JOIN time_dim td2        ON cs.cs_sold_time_sk = td2.t_time_sk
    JOIN item i2             ON cs.cs_item_sk      = i2.i_item_sk
    JOIN promotion p2        ON cs.cs_promo_sk     = p2.p_promo_sk
    JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm        ON cs.cs_ship_mode_sk    = sm.sm_ship_mode_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM order_numbers_without_return)
),

catalog_returns_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        i2.i_item_id,
        r.r_reason_desc,
        sm2.sm_type AS ship_mode_type
    FROM catalog_returns cr
    JOIN time_dim td3            ON cr.cr_returned_time_sk = td3.t_time_sk
    JOIN item i2                 ON cr.cr_item_sk         = i2.i_item_sk
    JOIN reason r                ON cr.cr_reason_sk       = r.r_reason_sk
    JOIN ship_mode sm2           ON cr.cr_ship_mode_sk    = sm2.sm_ship_mode_sk
),

web_returns_data AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        i3.i_item_id,
        r2.r_reason_desc,
        wp.wp_type AS web_page_type
    FROM web_returns wr
    JOIN time_dim td4          ON wr.wr_returned_time_sk = td4.t_time_sk
    JOIN item i3               ON wr.wr_item_sk          = i3.i_item_sk
    JOIN reason r2             ON wr.wr_reason_sk        = r2.r_reason_sk
    JOIN web_page wp           ON wr.wr_web_page_sk      = wp.wp_web_page_sk
),

combined_sales AS (
    SELECT
        sd.p_promo_id AS promo_id,
        sd.i_item_id,
        sd.ss_net_profit AS profit,
        sd.promo_rank
    FROM store_data sd
    WHERE sd.promo_rank <= 5

    UNION

    SELECT
        cd.p_promo_id,
        cd.i_item_id,
        cd.cs_net_profit,
        cd.promo_rank
    FROM catalog_data cd
    WHERE cd.promo_rank <= 5
),

ranked_sales AS (
    SELECT
        promo_id,
        i_item_id,
        profit,
        ROW_NUMBER() OVER (PARTITION BY promo_id ORDER BY profit DESC) AS rn
    FROM combined_sales
)
SELECT
    promo_id,
    i_item_id,
    SUM(profit) AS total_profit,
    COUNT(*)   AS transaction_cnt
FROM ranked_sales
WHERE rn <= 5
GROUP BY ROLLUP (promo_id, i_item_id)
HAVING (promo_id IS NOT NULL AND i_item_id IS NOT NULL)
ORDER BY total_profit DESC
LIMIT 100

WITH
    sampled_inventory AS (
        SELECT inv_item_sk, inv_quantity_on_hand
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    agg_catalog_sales AS (
        SELECT
            cs_item_sk,
            cs_sold_date_sk,
            cs_sold_time_sk,
            cs_catalog_page_sk,
            cs_ship_mode_sk,
            cs_promo_sk,
            cs_bill_cdemo_sk,
            cs_bill_hdemo_sk,
            cs_order_number,
            SUM(cs_net_paid)   AS total_net_paid,
            SUM(cs_net_profit) AS total_profit
        FROM catalog_sales
        GROUP BY
            cs_item_sk,
            cs_sold_date_sk,
            cs_sold_time_sk,
            cs_catalog_page_sk,
            cs_ship_mode_sk,
            cs_promo_sk,
            cs_bill_cdemo_sk,
            cs_bill_hdemo_sk,
            cs_order_number
    ),
    scalar_avg_profit AS (
        SELECT AVG(total_profit) AS avg_profit FROM agg_catalog_sales
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    cp.cp_department,
    sm.sm_type,
    hd.hd_income_band_sk,
    cs.total_net_paid,
    cs.total_profit,
    CASE
        WHEN cs.total_profit > (SELECT avg_profit FROM scalar_avg_profit) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY cs.total_profit DESC) AS dept_profit_rank,
    ROW_NUMBER() OVER (ORDER BY cs.total_net_paid DESC) AS overall_sales_rank
FROM
    agg_catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    -- LATERAL subquery referencing the preceding item row
    CROSS JOIN LATERAL (
        SELECT AVG(cs_l.cs_ext_sales_price) AS avg_item_sales
        FROM catalog_sales cs_l
        WHERE cs_l.cs_item_sk = i.i_item_sk
    ) l
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN sampled_inventory inv ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = cs.cs_order_number AND wr.wr_item_sk = i.i_item_sk
WHERE
    cp.cp_department = 'Electronics'
    AND sm.sm_code = 'AIR'
    AND t.t_shift = 'first'
UNION DISTINCT
SELECT
    i2.i_item_id,
    i2.i_product_name,
    cp2.cp_department,
    sm2.sm_type,
    hd2.hd_income_band_sk,
    cs2.total_net_paid,
    cs2.total_profit,
    CASE
        WHEN cs2.total_profit > (SELECT avg_profit FROM scalar_avg_profit) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    RANK() OVER (PARTITION BY cp2.cp_department ORDER BY cs2.total_profit DESC) AS dept_profit_rank,
    ROW_NUMBER() OVER (ORDER BY cs2.total_net_paid DESC) AS overall_sales_rank
FROM
    agg_catalog_sales cs2
    JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
    CROSS JOIN LATERAL (
        SELECT AVG(cs_l2.cs_ext_sales_price) AS avg_item_sales
        FROM catalog_sales cs_l2
        WHERE cs_l2.cs_item_sk = i2.i_item_sk
    ) l2
    JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
    JOIN ship_mode sm2 ON cs2.cs_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN promotion p2 ON cs2.cs_promo_sk = p2.p_promo_sk
    JOIN time_dim t2 ON cs2.cs_sold_time_sk = t2.t_time_sk
    JOIN customer_demographics cd2 ON cs2.cs_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON cs2.cs_bill_hdemo_sk = hd2.hd_demo_sk
    LEFT JOIN sampled_inventory inv2 ON i2.i_item_sk = inv2.inv_item_sk
    LEFT JOIN store_sales ss2 ON ss2.ss_item_sk = i2.i_item_sk AND ss2.ss_sold_time_sk = t2.t_time_sk
    LEFT JOIN store s2 ON ss2.ss_store_sk = s2.s_store_sk
    LEFT JOIN catalog_returns cr2 ON cr2.cr_order_number = cs2.cs_order_number AND cr2.cr_item_sk = i2.i_item_sk
    LEFT JOIN reason r2 ON cr2.cr_reason_sk = r2.r_reason_sk
    LEFT JOIN web_returns wr2 ON wr2.wr_order_number = cs2.cs_order_number AND wr2.wr_item_sk = i2.i_item_sk
WHERE
    cp2.cp_department = 'Books'
    AND sm2.sm_code = 'SEA'
    AND t2.t_shift = 'second'
ORDER BY
    profit_category,
    dept_profit_rank

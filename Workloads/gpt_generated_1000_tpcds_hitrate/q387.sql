WITH base AS (
    SELECT
        p.p_channel_catalog,
        d.d_year,
        cc.cc_name,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cr.cr_return_amount,
        (
            SELECT AVG(cs2.cs_ext_discount_amt)
            FROM catalog_sales cs2
            WHERE cs2.cs_promo_sk = p.p_promo_sk
        ) AS avg_discount,
        inv_l.total_inventory
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN LATERAL (
        SELECT SUM(inv_quantity_on_hand) AS total_inventory
        FROM inventory inv
        WHERE inv.inv_date_sk = d.d_date_sk
    ) inv_l ON TRUE
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
        AND ss.ss_cdemo_sk = cd.cd_demo_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'Y'
      AND d.d_year BETWEEN 2000 AND 2002
      AND t.t_hour BETWEEN 9 AND 17
),
agg AS (
    SELECT
        p_channel_catalog,
        d_year,
        cc_name,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(COALESCE(cr_return_amount, 0)) AS total_returns,
        MIN(avg_discount) AS avg_discount,
        MIN(total_inventory) AS total_inventory
    FROM base
    GROUP BY ROLLUP(p_channel_catalog, d_year, cc_name)
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY p_channel_catalog ORDER BY total_profit DESC) AS profit_rank
    FROM agg
    WHERE p_channel_catalog IS NOT NULL
)
SELECT
    p_channel_catalog,
    d_year,
    cc_name,
    total_sales,
    total_profit,
    total_returns,
    avg_discount,
    total_inventory,
    CASE
        WHEN total_profit > 1000000 THEN 'High'
        WHEN total_profit > 500000  THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    profit_rank
FROM ranked
WHERE profit_rank <= 5
ORDER BY p_channel_catalog, d_year, profit_rank
LIMIT 100

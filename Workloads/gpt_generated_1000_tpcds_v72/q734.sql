/*
Goal: Summarize net revenue and profit of electronic items sold in California stores for the years 2000‑2002, showing subtotals by year, category and store, ranking stores by profit within each year, and filtering to only those sales that have related catalog returns, web sales, inventory, store returns and belong to higher‑income households.
*/
WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        ss.ss_item_sk,
        i.i_category,
        d.d_year,
        hd.hd_demo_sk AS hh_demo_sk,
        SUM(ss.ss_net_paid)          AS total_net_paid,
        SUM(ss.ss_net_profit)        AS total_net_profit,
        COUNT(*)                     AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i              ON ss.ss_item_sk = i.i_item_sk
    JOIN store s             ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c          ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_category = 'Electronics'
      AND s.s_state = 'CA'
    GROUP BY GROUPING SETS (
        (ss.ss_store_sk, s.s_store_name, s.s_state, ss.ss_item_sk, i.i_category, d.d_year, hd.hd_demo_sk),
        (i.i_category, d.d_year, hd.hd_demo_sk),
        (d.d_year, hd.hd_demo_sk),
        (hd.hd_demo_sk)
    )
)
SELECT
    sa.d_year,
    sa.s_store_name,
    sa.i_category,
    sa.total_net_paid,
    sa.total_net_profit,
    CASE
        WHEN sa.total_net_profit > 100000 THEN 'High'
        WHEN sa.total_net_profit >  50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_bucket,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.total_net_profit DESC) AS profit_rank
FROM sales_agg sa
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN call_center cc        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d2           ON cr.cr_returned_date_sk = d2.d_date_sk
    WHERE cr.cr_item_sk = sa.ss_item_sk
      AND d2.d_year = sa.d_year
      AND cc.cc_country = 'United States'
      AND cp.cp_type = 'PROMO'
)
AND EXISTS (
    SELECT 1
    FROM web_sales ws
    JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d3           ON ws.ws_sold_date_sk = d3.d_date_sk
    WHERE ws.ws_item_sk = sa.ss_item_sk
      AND d3.d_year = sa.d_year
      AND wp.wp_type = 'HOME'
      AND ws.ws_quantity > 5
)
AND EXISTS (
    SELECT 1
    FROM inventory inv
    JOIN warehouse w          ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d4           ON inv.inv_date_sk = d4.d_date_sk
    WHERE inv.inv_item_sk = sa.ss_item_sk
      AND d4.d_year = sa.d_year
      AND w.w_state = 'CA'
)
AND EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN date_dim d5           ON sr.sr_returned_date_sk = d5.d_date_sk
    WHERE sr.sr_item_sk = sa.ss_item_sk
      AND d5.d_year = sa.d_year
      AND sr.sr_net_loss > 0
)
AND EXISTS (
    SELECT 1
    FROM household_demographics hd2
    JOIN income_band ib        ON hd2.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd2.hd_demo_sk = sa.hh_demo_sk
      AND ib.ib_upper_bound > 50000
)
ORDER BY sa.d_year, profit_rank
LIMIT 100

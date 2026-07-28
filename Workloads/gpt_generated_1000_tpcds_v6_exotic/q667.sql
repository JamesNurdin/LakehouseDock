WITH revenue AS (
    SELECT
        s.s_store_id,
        i.i_item_id,
        cp.cp_catalog_page_number,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_return_qty,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_store_return_qty
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd_sales ON cs.cs_bill_cdemo_sk = cd_sales.cd_demo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2001
      AND i.i_class = 'sports-apparel'
      AND sm.sm_code = 'AIR'
      AND cp.cp_catalog_page_number IN (9, 15)
    GROUP BY
        s.s_store_id,
        i.i_item_id,
        cp.cp_catalog_page_number
)
SELECT
    r.s_store_id,
    r.i_item_id,
    r.cp_catalog_page_number,
    r.total_sales,
    r.total_profit,
    r.order_cnt,
    r.total_return_qty,
    r.total_store_return_qty,
    RANK() OVER (PARTITION BY r.i_item_id ORDER BY r.total_profit DESC) AS profit_rank_by_item,
    CASE
        WHEN r.total_profit > (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
            WHERE d2.d_year = 2001
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM revenue r
ORDER BY r.total_profit DESC
LIMIT 100

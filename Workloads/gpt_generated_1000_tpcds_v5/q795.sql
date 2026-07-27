WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_company,
        cc.cc_name,
        td.t_hour,
        i.i_item_sk,
        i.i_category,
        SUM(cs.cs_net_profit)               AS total_profit,
        SUM(cs.cs_quantity)                  AS total_qty,
        COUNT(*)                             AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_company = 6                                     -- filter 1
      AND sm.sm_carrier = 'USPS'                                 -- filter 2
      AND cp.cp_department = 'Sports'                            -- filter 3
      AND i.i_item_sk IN (
            SELECT i2.i_item_sk
            FROM item i2
            WHERE i2.i_current_price > 100                     -- sub‑query filter
        )
      AND cs.cs_quantity > 0                                    -- filter 4
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_company,
        cc.cc_name,
        td.t_hour,
        i.i_item_sk,
        i.i_category
)
SELECT
    sa.cc_name,
    sa.cc_company,
    sa.t_hour,
    sa.i_category,
    sa.total_profit,
    sa.total_qty,
    sa.sales_cnt,
    RANK() OVER (PARTITION BY sa.t_hour ORDER BY sa.total_profit DESC) AS profit_rank_by_hour,
    SUM(sa.total_profit) OVER (
        PARTITION BY sa.cc_company
        ORDER BY sa.t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_profit_by_company_hour
FROM sales_agg sa
ORDER BY sa.t_hour, profit_rank_by_hour
LIMIT 100

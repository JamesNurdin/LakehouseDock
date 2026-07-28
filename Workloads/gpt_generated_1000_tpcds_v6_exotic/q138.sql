WITH distinct_cc AS (
    SELECT DISTINCT cc.cc_call_center_sk
    FROM tpcds.call_center cc
    WHERE cc.cc_country = 'United States'
),

sales_agg AS (
    SELECT
        i.i_category,
        i.i_class,
        w.w_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i                     ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w                ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.call_center cc             ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN distinct_cc dc                   ON cs.cs_call_center_sk = dc.cc_call_center_sk
    JOIN tpcds.time_dim t                 ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib             ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_country = 'United States'
      AND w.w_gmt_offset = -5.00
      AND i.i_class IN ('sports-apparel','pop')
      AND t.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 50000
    GROUP BY ROLLUP (i.i_category, i.i_class, w.w_state)
),

returns_agg AS (
    SELECT
        i.i_category,
        i.i_class,
        w.w_state,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
    FROM tpcds.catalog_returns cr
    JOIN tpcds.catalog_sales cs           ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.item i                     ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w                ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.call_center cc             ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN distinct_cc dc                   ON cr.cr_call_center_sk = dc.cc_call_center_sk
    JOIN tpcds.time_dim t                 ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN tpcds.household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib             ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_country = 'United States'
      AND w.w_gmt_offset = -5.00
      AND i.i_class IN ('sports-apparel','pop')
      AND t.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 50000
    GROUP BY ROLLUP (i.i_category, i.i_class, w.w_state)
),

combined AS (
    SELECT
        i_category,
        i_class,
        w_state,
        total_sales,
        total_profit,
        NULL AS total_returns,
        NULL AS total_loss,
        distinct_orders,
        NULL AS distinct_return_orders,
        'sales' AS src
    FROM sales_agg
    UNION ALL
    SELECT
        i_category,
        i_class,
        w_state,
        NULL,
        NULL,
        total_returns,
        total_loss,
        NULL,
        distinct_return_orders,
        'returns' AS src
    FROM returns_agg
)

SELECT
    c.i_category,
    c.i_class,
    c.w_state,
    SUM(COALESCE(c.total_sales, 0))        AS agg_sales,
    SUM(COALESCE(c.total_profit, 0))       AS agg_profit,
    SUM(COALESCE(c.total_returns, 0))      AS agg_returns,
    SUM(COALESCE(c.total_loss, 0))         AS agg_loss,
    COUNT(DISTINCT CASE WHEN c.src = 'sales'   THEN c.distinct_orders END)        AS sales_orders,
    COUNT(DISTINCT CASE WHEN c.src = 'returns' THEN c.distinct_return_orders END) AS return_orders,
    ROW_NUMBER() OVER (PARTITION BY c.w_state ORDER BY SUM(COALESCE(c.total_sales, 0)) DESC) AS sales_rank_state,
    RANK()       OVER (ORDER BY SUM(COALESCE(c.total_profit, 0)) DESC)                     AS profit_rank_global,
    CASE
        WHEN SUM(COALESCE(c.total_sales, 0)) > 0 AND SUM(COALESCE(c.total_returns, 0)) > 0
        THEN (SUM(COALESCE(c.total_sales, 0)) - SUM(COALESCE(c.total_returns, 0))) / SUM(COALESCE(c.total_sales, 0))
        ELSE NULL
    END AS sales_return_ratio
FROM combined c
WHERE c.i_category IS NOT NULL
GROUP BY GROUPING SETS (
    (c.i_category, c.i_class, c.w_state),
    (c.i_category, c.i_class),
    (c.i_category),
    ()
)
ORDER BY agg_profit DESC, sales_rank_state
LIMIT 100

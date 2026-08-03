WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
agg AS (
    SELECT
        w.w_warehouse_name,
        i.i_category,
        sm.sm_type,
        r.r_reason_desc,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM cs_sample cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    /* Join web_returns through shared dimensions */
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE ib.ib_upper_bound = 150000
      AND ib.ib_lower_bound >= 60000
      AND cs.cs_quantity BETWEEN 1 AND 10
      AND cs.cs_sales_price > 20
      AND wr.wr_return_amt > 100
      AND w.w_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY w.w_warehouse_name, i.i_category, sm.sm_type, r.r_reason_desc
)
SELECT
    a.w_warehouse_name,
    a.i_category,
    a.sm_type,
    a.r_reason_desc,
    a.total_sales,
    a.total_returns,
    a.order_cnt,
    a.avg_sales_price,
    a.profit_level,
    SUM(a.total_sales) OVER (
        PARTITION BY a.i_category
        ORDER BY a.w_warehouse_name
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_sales_by_category
FROM agg a
CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2) d
ORDER BY a.w_warehouse_name, a.i_category

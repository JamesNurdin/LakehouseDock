WITH agg AS (
    SELECT
        i.i_category AS category,
        i.i_brand AS brand,
        t.t_shift AS shift,
        s.s_store_name AS store_name,
        w.w_warehouse_name AS warehouse_name,
        sm.sm_type AS ship_type,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(wr.wr_return_amt) AS total_web_returns,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(wr.wr_net_loss) AS total_web_net_loss
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk AND ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk AND wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_refund ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer_demographics cd_return ON wr.wr_returning_cdemo_sk = cd_return.cd_demo_sk
    GROUP BY ROLLUP (i.i_category, i.i_brand, t.t_shift, s.s_store_name, w.w_warehouse_name, sm.sm_type)
)
SELECT
    category,
    brand,
    shift,
    store_name,
    warehouse_name,
    ship_type,
    total_catalog_sales,
    total_store_sales,
    total_web_returns,
    total_catalog_profit,
    total_store_profit,
    total_web_net_loss,
    ROW_NUMBER() OVER (
        PARTITION BY category
        ORDER BY (COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0) - COALESCE(total_web_returns, 0)) DESC
    ) AS category_rank
FROM agg
ORDER BY total_catalog_sales DESC
LIMIT 100

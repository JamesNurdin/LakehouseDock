WITH agg_inventory AS (
    SELECT inv_date_sk,
           inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_date_sk, inv_item_sk, inv_warehouse_sk
),
sales_dates AS (
    SELECT DISTINCT ss_sold_date_sk AS d_date_sk
    FROM store_sales
    WHERE ss_quantity > 0
),
return_dates AS (
    SELECT DISTINCT cr_returned_date_sk AS d_date_sk
    FROM catalog_returns
    UNION
    SELECT DISTINCT wr_returned_date_sk AS d_date_sk
    FROM web_returns
),
non_return_dates AS (
    SELECT d_date_sk
    FROM sales_dates
    EXCEPT
    SELECT d_date_sk
    FROM return_dates
),
base AS (
    SELECT d.d_date_sk,
           d.d_year,
           i.i_item_sk,
           i.i_category,
           i.i_brand,
           s.s_store_sk,
           s.s_store_name,
           s.s_state,
           c.c_customer_sk,
           cd.cd_gender,
           hd.hd_vehicle_count,
           ib.ib_lower_bound,
           cc.cc_call_center_id,
           ws.web_state,
           ss.ss_net_profit,
           agg_inventory.total_qty_on_hand,
           cr.cr_net_loss,
           wr.wr_net_loss
    FROM non_return_dates nd
    JOIN date_dim d ON nd.d_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN agg_inventory ON agg_inventory.inv_date_sk = d.d_date_sk
                         AND agg_inventory.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON agg_inventory.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                                 AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                              AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
      AND s.s_state = 'CA'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_lower_bound >= 50000
)
SELECT
    d_year,
    s_store_name,
    i_category,
    i_brand,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(total_qty_on_hand) AS total_quantity_on_hand,
    SUM(CASE WHEN cd_gender = 'M' THEN ss_net_profit ELSE 0 END) AS male_net_profit,
    SUM(CASE WHEN cd_gender <> 'M' THEN ss_net_profit ELSE 0 END) AS non_male_net_profit,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    COUNT(DISTINCT cc_call_center_id) AS distinct_call_centers,
    AVG(cr_net_loss) AS avg_catalog_return_net_loss,
    AVG(wr_net_loss) AS avg_web_return_net_loss
FROM base
GROUP BY GROUPING SETS (
    (d_year, s_store_name, i_category, i_brand),
    (d_year, s_store_name, i_category),
    (d_year, s_store_name),
    (d_year),
    ()
)
ORDER BY d_year DESC, s_store_name, i_category, i_brand
LIMIT 100

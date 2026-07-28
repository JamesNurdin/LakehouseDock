WITH joined_data AS (
    SELECT
        d.d_year,
        cc.cc_name,
        cc.cc_class,
        hd.hd_income_band_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        cs.cs_net_profit,
        sr.sr_net_loss,
        i.inv_quantity_on_hand AS i_quantity_on_hand,
        cd.cd_gender,
        ca.ca_state,
        CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS qty_type,
        cs.cs_quantity
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_item_sk = ss.ss_item_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                         -- predicate 1
      AND hd.hd_dep_count >= 1                                   -- predicate 2
      AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00                -- predicate 3
      AND ca.ca_state IN ('CA', 'TX', 'NY')                     -- predicate 4
      AND cs.cs_quantity > 0                                     -- predicate 5
),
aggregated AS (
    SELECT
        d_year,
        cc_name,
        cc_class,
        hd_income_band_sk,
        qty_type,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(cs_net_profit) AS total_catalog_profit,
        SUM(sr_net_loss)   AS total_return_loss,
        COUNT(DISTINCT ss_ticket_number) AS distinct_sales_cnt,
        AVG(i_quantity_on_hand) AS avg_inventory_qty
    FROM joined_data
    GROUP BY d_year, cc_name, cc_class, hd_income_band_sk, qty_type
)
SELECT
    d_year,
    cc_name,
    cc_class,
    hd_income_band_sk,
    qty_type,
    total_store_profit,
    total_catalog_profit,
    total_return_loss,
    distinct_sales_cnt,
    avg_inventory_qty,
    CASE
        WHEN total_store_profit > 10000 THEN 'High'
        WHEN total_store_profit > 0    THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (SELECT AVG(total_store_profit) FROM aggregated) AS overall_avg_store_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_store_profit DESC) AS profit_rank
FROM aggregated
WHERE total_store_profit > (SELECT AVG(total_store_profit) FROM aggregated)
ORDER BY d_year, profit_rank
LIMIT 100

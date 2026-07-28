WITH sales_agg AS (
    SELECT
        i.i_manufact,
        inv.inv_warehouse_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit)       AS total_profit,
        SUM(ss.ss_quantity)         AS total_quantity,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM tpcds.store_sales ss
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    WHERE i.i_manufact IN ('callyeingeing', 'barcallyable')
      AND i.i_units = 'Dozen'
      AND ca.ca_state = 'CA'
      AND ca.ca_country = 'United States'
      AND ss.ss_sold_date_sk = 2450955
      AND ss.ss_ext_sales_price > 1000
      AND (inv.inv_quantity_on_hand >= 200 OR inv.inv_quantity_on_hand IS NULL)
    GROUP BY ROLLUP (i.i_manufact, inv.inv_warehouse_sk)
)
SELECT
    i_manufact,
    inv_warehouse_sk,
    total_sales,
    total_profit,
    total_quantity,
    profit_flag,
    ROW_NUMBER() OVER (PARTITION BY i_manufact ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY i_manufact, inv_warehouse_sk
LIMIT 100

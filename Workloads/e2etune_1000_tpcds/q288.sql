WITH sales_inventory AS (
    SELECT
        ib.ib_income_band_sk AS ib_income_band_sk,
        i.inv_warehouse_sk AS inv_warehouse_sk,
        SUM(s.ss_net_profit) AS total_net_profit,
        SUM(s.ss_ext_sales_price) AS total_sales,
        AVG(s.ss_ext_discount_amt) AS avg_discount
    FROM inventory i
    JOIN store_sales s
        ON i.inv_item_sk = s.ss_item_sk
        AND i.inv_date_sk = s.ss_sold_date_sk
    JOIN income_band ib
        ON i.inv_quantity_on_hand BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE i.inv_date_sk BETWEEN 2450800 AND 2451100
      AND i.inv_warehouse_sk IN (1, 9, 10, 15, 16)
      AND s.ss_net_paid > 0
    GROUP BY ib.ib_income_band_sk, i.inv_warehouse_sk
)
SELECT
    ib_income_band_sk,
    inv_warehouse_sk,
    total_net_profit,
    total_sales,
    avg_discount,
    RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_inventory
ORDER BY ib_income_band_sk, profit_rank

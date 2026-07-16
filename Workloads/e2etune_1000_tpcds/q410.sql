WITH agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.inv_warehouse_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM store_sales ss
    JOIN inventory i
      ON ss.ss_item_sk = i.inv_item_sk
     AND ss.ss_sold_date_sk = i.inv_date_sk
    JOIN income_band ib
      ON ss.ss_customer_sk = ib.ib_income_band_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
      AND i.inv_quantity_on_hand > 0
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, i.inv_warehouse_sk
    HAVING SUM(ss.ss_ext_sales_price) > 10000
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY ib_income_band_sk ORDER BY total_sales DESC) AS sales_rank,
        CASE WHEN total_inventory_on_hand = 0 THEN NULL
             ELSE CAST(total_quantity AS DOUBLE) / total_inventory_on_hand END AS inventory_turnover
    FROM agg
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    inv_warehouse_sk,
    total_sales,
    total_quantity,
    avg_discount,
    total_net_profit,
    total_inventory_on_hand,
    inventory_turnover,
    sales_rank
FROM ranked
WHERE sales_rank <= 5
ORDER BY ib_income_band_sk, sales_rank

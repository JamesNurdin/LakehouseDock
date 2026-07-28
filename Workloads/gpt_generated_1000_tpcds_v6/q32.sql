WITH sales_by_date AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
        MIN(cs.cs_net_profit) AS min_profit,
        MAX(cs.cs_net_profit) AS max_profit
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_wholesale_cost > 50
    GROUP BY cs.cs_sold_date_sk, cs.cs_warehouse_sk
),

inventory_by_date AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 100
    GROUP BY inv.inv_date_sk, inv.inv_warehouse_sk
),

high_low_months AS (
    SELECT d.d_year,
           d.d_month_seq,
           'HIGH' AS profit_category
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
    HAVING SUM(cs.cs_net_profit) > 100000
    UNION DISTINCT
    SELECT d.d_year,
           d.d_month_seq,
           'LOW' AS profit_category
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
    HAVING SUM(cs.cs_net_profit) < 10000
)
SELECT
    d.d_year,
    d.d_month_seq,
    sb.total_sales,
    sb.avg_discount,
    sb.distinct_items_sold,
    ib.total_on_hand,
    hl.profit_category,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_profit
FROM sales_by_date sb
JOIN date_dim d
     ON sb.cs_sold_date_sk = d.d_date_sk
LEFT JOIN inventory_by_date ib
     ON ib.inv_date_sk = d.d_date_sk
    AND ib.inv_warehouse_sk = sb.cs_warehouse_sk
JOIN high_low_months hl
     ON hl.d_year = d.d_year
    AND hl.d_month_seq = d.d_month_seq
WHERE d.d_current_month = 'Y'
  AND d.d_month_seq BETWEEN 3 AND 10
  AND d.d_year = 2001
  AND sb.total_sales > 5000
ORDER BY sb.total_sales DESC
LIMIT 100

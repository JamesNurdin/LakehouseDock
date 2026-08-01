WITH base AS (
    SELECT
        cp.cp_department AS department,
        d_cs_sold.d_year AS year,
        d_cs_sold.d_month_seq AS month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
        SUM(cs.cs_ext_discount_amt) / (
            SELECT AVG(cs2.cs_ext_discount_amt)
            FROM catalog_sales cs2
        ) AS discount_vs_avg
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_cs_sold
        ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN date_dim d_cs_ship
        ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    JOIN date_dim d_ss_sold
        ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d_cs_sold.d_date_sk
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d_cs_sold.d_year = 1999
      AND cp.cp_department = 'Sports'
      AND p.p_purpose = 'Unknown'
      AND i.inv_quantity_on_hand > 500
      AND ss.ss_quantity >= 2
      AND cs.cs_quantity > 1
      AND cs.cs_sales_price > 100
    GROUP BY cp.cp_department, d_cs_sold.d_year, d_cs_sold.d_month_seq
)
SELECT
    department,
    year,
    month_seq,
    total_sales,
    total_profit,
    avg_discount,
    total_store_sales,
    total_inventory_qty,
    distinct_items,
    profit_category,
    discount_vs_avg,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (
        PARTITION BY department
        ORDER BY year, month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_by_dept
FROM base
ORDER BY total_sales DESC
LIMIT 100

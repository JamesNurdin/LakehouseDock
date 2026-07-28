WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        d_sold.d_year,
        d_sold.d_month_seq,
        sm.sm_type,
        ss.ss_quantity AS store_quantity,
        wr.wr_return_quantity,
        wr.wr_net_loss
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2002
      AND cs.cs_net_paid_inc_ship_tax > 1000.00
      AND sm.sm_type = 'AIR'
)
SELECT
    d_year,
    d_month_seq,
    sm_type,
    SUM(cs_ext_sales_price)                         AS total_sales,
    SUM(cs_quantity)                                AS total_catalog_quantity,
    SUM(store_quantity)                             AS total_store_quantity,
    SUM(wr_return_quantity)                        AS total_return_qty,
    SUM(wr_net_loss)                                AS total_return_loss,
    AVG(cs_net_paid_inc_ship_tax)                  AS avg_net_paid,
    CASE
        WHEN SUM(cs_ext_sales_price) > 20000.00 THEN 'HIGH'
        ELSE 'NORMAL'
    END                                            AS sales_category,
    -- scalar sub‑query for overall average net paid across the whole catalog_sales table
    (SELECT AVG(cs_net_paid_inc_ship_tax) FROM catalog_sales) AS overall_avg_net_paid,
    -- cumulative sales within each fiscal year ordered by month_seq
    SUM(SUM(cs_ext_sales_price)) OVER (
        PARTITION BY d_year
        ORDER BY d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                               AS cumulative_sales_year
FROM base
GROUP BY ROLLUP (d_year, d_month_seq, sm_type)
HAVING SUM(cs_ext_sales_price) > 5000.00
ORDER BY d_year, d_month_seq, sm_type
LIMIT 100

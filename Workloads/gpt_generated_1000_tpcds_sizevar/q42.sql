WITH
    inv_agg AS (
        SELECT
            inv_date_sk,
            inv_item_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
        GROUP BY inv_date_sk, inv_item_sk
    ),
    sales_agg AS (
        SELECT
            cs_sold_date_sk,
            cs_item_sk,
            SUM(cs_net_paid_inc_ship_tax) AS total_net_paid
        FROM catalog_sales
        GROUP BY cs_sold_date_sk, cs_item_sk
    ),
    sales_join AS (
        SELECT
            d_sold.d_year AS d_year,
            s.s_store_name AS s_store_name,
            sm.sm_type AS sm_type,
            SUM(sa.total_net_paid) AS total_sales,
            SUM(i.total_qty) AS total_qty,
            SUM(sr.sr_return_amt) AS total_returns,
            COUNT(DISTINCT r.r_reason_desc) AS distinct_reasons
        FROM sales_agg sa
        JOIN catalog_sales cs
            ON cs.cs_sold_date_sk = sa.cs_sold_date_sk
           AND cs.cs_item_sk = sa.cs_item_sk
        JOIN date_dim d_sold
            ON sa.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship
            ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN time_dim t_sold
            ON cs.cs_sold_time_sk = t_sold.t_time_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN inv_agg i
            ON sa.cs_sold_date_sk = i.inv_date_sk
           AND sa.cs_item_sk = i.inv_item_sk
        JOIN store_returns sr
            ON sr.sr_returned_date_sk = d_sold.d_date_sk
        JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d_store_closed
            ON s.s_closed_date_sk = d_store_closed.d_date_sk
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        JOIN date_dim d_return
            ON sr.sr_returned_date_sk = d_return.d_date_sk
        JOIN time_dim t_return
            ON sr.sr_return_time_sk = t_return.t_time_sk
        WHERE EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = s.s_store_sk
              AND sr2.sr_returned_date_sk = d_sold.d_date_sk
        )
        GROUP BY d_sold.d_year, s.s_store_name, sm.sm_type
    )
SELECT
    d_year,
    s_store_name,
    sm_type,
    total_sales,
    total_qty,
    total_returns,
    distinct_reasons,
    LAG(total_sales) OVER (PARTITION BY s_store_name ORDER BY d_year) AS lag_total_sales
FROM sales_join
UNION DISTINCT
SELECT
    d_year,
    s_store_name,
    sm_type,
    total_sales,
    total_qty,
    total_returns,
    distinct_reasons,
    LAG(total_sales) OVER (PARTITION BY s_store_name ORDER BY d_year) AS lag_total_sales
FROM sales_join
ORDER BY d_year, s_store_name
LIMIT 100

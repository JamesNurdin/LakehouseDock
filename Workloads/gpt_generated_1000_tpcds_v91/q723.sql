/*
  Goal: Analyze total sales net paid and total return net loss by warehouse, reason and sales date shift, rank warehouses by sales volume, and keep only orders that have at least one return with a positive return amount. The query joins all seven selected tables, re‑uses date and time dimensions under different aliases, includes a DISTINCT subquery, an EXISTS correlated subquery, a window function, and orders the final result.
*/
WITH distinct_reasons AS (
    SELECT DISTINCT r_reason_sk, r_reason_desc
    FROM reason
),
joined_data AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cr.cr_net_loss,
        wr.wr_net_loss,
        w_sales.w_warehouse_name      AS sales_warehouse,
        w_return.w_warehouse_name     AS return_warehouse,
        d_sold.d_year                  AS sale_year,
        t_sold.t_shift                 AS sale_shift,
        r_reason.r_reason_desc,
        d_return.d_year                AS return_year,
        d_wr.d_year                    AS web_return_year
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN warehouse w_sales
      ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
    JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    JOIN date_dim d_return
      ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return
      ON cr.cr_returned_time_sk = t_return.t_time_sk
    JOIN warehouse w_return
      ON cr.cr_warehouse_sk = w_return.w_warehouse_sk
    JOIN distinct_reasons r_reason
      ON cr.cr_reason_sk = r_reason.r_reason_sk
    JOIN web_returns wr
      ON wr.wr_reason_sk = r_reason.r_reason_sk
    JOIN date_dim d_wr
      ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr
      ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = cs.cs_item_sk
          AND cr2.cr_return_amount > 0
    )
),
aggregated AS (
    SELECT
        jd.sales_warehouse,
        jd.return_warehouse,
        jd.r_reason_desc,
        jd.sale_year,
        jd.sale_shift,
        SUM(jd.cs_net_paid)        AS total_sales_net_paid,
        SUM(jd.cr_net_loss)        AS total_return_net_loss,
        SUM(jd.wr_net_loss)        AS total_web_return_net_loss,
        COUNT(DISTINCT jd.cs_item_sk) AS distinct_items_sold,
        SUM(jd.cs_quantity)        AS total_quantity_sold
    FROM joined_data jd
    GROUP BY
        jd.sales_warehouse,
        jd.return_warehouse,
        jd.r_reason_desc,
        jd.sale_year,
        jd.sale_shift
)
SELECT
    a.sales_warehouse,
    a.return_warehouse,
    a.r_reason_desc,
    a.sale_year,
    a.sale_shift,
    a.total_sales_net_paid,
    a.total_return_net_loss,
    a.total_web_return_net_loss,
    a.distinct_items_sold,
    a.total_quantity_sold,
    RANK() OVER (PARTITION BY a.sales_warehouse ORDER BY a.total_sales_net_paid DESC) AS sales_rank_by_warehouse
FROM aggregated a
ORDER BY a.total_sales_net_paid DESC
LIMIT 100

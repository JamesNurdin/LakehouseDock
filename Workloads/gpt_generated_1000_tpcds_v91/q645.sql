WITH base AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        d_sold.d_year,
        d_sold.d_month_seq,
        MAX(i.i_manager_id) AS manager_id,
        MAX(i.i_formulation) AS formulation,
        MAX(i.i_item_sk) AS item_sk,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = cs.cs_item_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = cs.cs_item_sk
    JOIN item i
        ON i.i_item_sk = cs.cs_item_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE d_sold.d_year = 2001
      AND t_sold.t_sub_shift = 'night'
      AND i.i_manager_id IN (11, 63, 23)
      AND i.i_formulation LIKE '%seashell%'
      AND sr.sr_return_ship_cost > 20
      AND cs.cs_quantity > 1
    GROUP BY
        GROUPING SETS (
            (i.i_item_id, i.i_brand, d_sold.d_year),
            (i.i_brand, d_sold.d_month_seq)
        )
)
SELECT
    b.i_item_id,
    b.i_brand,
    b.d_year,
    b.d_month_seq,
    b.manager_id,
    b.formulation,
    b.total_sales,
    b.total_quantity,
    b.total_catalog_return_loss,
    b.total_store_return_loss,
    b.total_web_return_loss,
    b.order_cnt,
    (SELECT MAX(cr2.cr_net_loss)
     FROM catalog_returns cr2
     WHERE cr2.cr_item_sk = b.item_sk) AS max_catalog_return_loss,
    (SELECT SUM(sr2.sr_return_amt)
     FROM store_returns sr2
     WHERE sr2.sr_item_sk = b.item_sk) AS total_store_return_amt_all_time,
    LAG(b.total_sales) OVER (PARTITION BY b.i_brand ORDER BY b.d_year) AS prev_year_sales,
    SUM(b.total_sales) OVER (PARTITION BY b.i_brand ORDER BY COALESCE(b.d_year, 0), COALESCE(b.d_month_seq, 0) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM base b
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr3
    WHERE cr3.cr_item_sk = b.item_sk
      AND cr3.cr_net_loss > 200
)
ORDER BY b.i_brand, b.d_year DESC NULLS LAST, b.total_sales DESC
LIMIT 100

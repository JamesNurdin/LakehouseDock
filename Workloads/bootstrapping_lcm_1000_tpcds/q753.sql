WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_ret.d_date AS return_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        t_ret.t_hour AS return_hour,
        t_ret.t_meal_time AS return_meal_time,
        cs.cs_item_sk,
        cs.cs_order_number,
        SUM(cs.cs_quantity) AS total_sold_qty,
        SUM(cs.cs_net_paid) AS total_sales_net_paid,
        SUM(cs.cs_net_profit) AS total_sales_net_profit,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_net_loss,
        (SUM(cs.cs_net_paid) - SUM(cr.cr_net_loss)) AS net_revenue_after_returns,
        CASE WHEN SUM(cs.cs_quantity) > 0
            THEN (SUM(cr.cr_return_quantity) * 1.0 / SUM(cs.cs_quantity))
            ELSE NULL
        END AS return_rate
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret
        ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    WHERE cr.cr_return_amount > 0
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_ret.d_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        t_ret.t_hour,
        t_ret.t_meal_time,
        cs.cs_item_sk,
        cs.cs_order_number
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.return_date,
    agg.d_year,
    agg.d_month_seq,
    agg.return_hour,
    agg.return_meal_time,
    agg.cs_item_sk,
    agg.cs_order_number,
    agg.total_sold_qty,
    agg.total_sales_net_paid,
    agg.total_sales_net_profit,
    agg.total_return_qty,
    agg.total_return_amount,
    agg.total_return_net_loss,
    agg.net_revenue_after_returns,
    agg.return_rate,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_id ORDER BY agg.net_revenue_after_returns DESC) AS store_rank
FROM agg
ORDER BY agg.net_revenue_after_returns DESC
LIMIT 100

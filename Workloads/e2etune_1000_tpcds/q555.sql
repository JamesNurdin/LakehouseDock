WITH agg AS (
    SELECT
        i.i_category,
        sm.sm_ship_mode_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t_sales
        ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN time_dim t_returns
        ON cr.cr_returned_time_sk = t_returns.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        r.r_reason_desc = 'Damaged'
        AND t_sales.t_hour BETWEEN 9 AND 17
        AND t_returns.t_hour BETWEEN 9 AND 17
        AND sm.sm_type = 'GROUND'
        AND i.i_category = 'Electronics'
        AND cr.cr_returned_date_sk BETWEEN 2450926 AND 2451065
    GROUP BY
        i.i_category,
        sm.sm_ship_mode_id
    HAVING
        SUM(cs.cs_ext_sales_price) > 10000
)
SELECT
    i_category,
    sm_ship_mode_id,
    total_sales,
    total_returns,
    total_net_profit,
    CASE WHEN total_sales = 0 THEN 0 ELSE total_returns / total_sales END AS return_rate,
    RANK() OVER (PARTITION BY i_category ORDER BY CASE WHEN total_sales = 0 THEN 0 ELSE total_returns / total_sales END DESC) AS return_rate_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 50

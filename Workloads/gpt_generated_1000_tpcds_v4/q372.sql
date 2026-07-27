/*
Goal: Identify the items that generated the highest combined net loss from catalog returns and store returns, applying multiple realistic filters and ranking the results.
*/
WITH base_data AS (
    SELECT
        cr.cr_item_sk,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        cr.cr_net_loss        AS cr_net_loss,
        sr.sr_net_loss        AS sr_net_loss,
        cr.cr_warehouse_sk,
        cr.cr_refunded_customer_sk,
        r.r_reason_desc,
        i.i_current_price,
        cs.cs_quantity,
        cs.cs_ext_list_price,
        t_cr.t_hour           AS return_hour,
        sr.sr_return_quantity
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    WHERE
        cr.cr_warehouse_sk IN (10, 5)
        AND cr.cr_refunded_customer_sk > 1000000
        AND r.r_reason_desc LIKE '%damaged%'
        AND i.i_current_price > 100
        AND cs.cs_quantity >= 30
        AND cs.cs_ext_list_price BETWEEN 2000 AND 5000
        AND t_cr.t_hour BETWEEN 9 AND 17
        AND sr.sr_return_quantity > 0
)
SELECT
    i_item_sk,
    i_item_id,
    i_product_name,
    total_cr_net_loss,
    total_sr_net_loss,
    total_loss,
    RANK() OVER (ORDER BY total_loss DESC) AS loss_rank,
    CASE WHEN total_loss > 10000 THEN 'High' ELSE 'Medium' END AS loss_category
FROM (
    SELECT
        i_item_sk,
        i_item_id,
        i_product_name,
        SUM(cr_net_loss) AS total_cr_net_loss,
        SUM(sr_net_loss) AS total_sr_net_loss,
        SUM(cr_net_loss) + SUM(sr_net_loss) AS total_loss
    FROM base_data
    GROUP BY i_item_sk, i_item_id, i_product_name
) agg
ORDER BY loss_rank
LIMIT 100

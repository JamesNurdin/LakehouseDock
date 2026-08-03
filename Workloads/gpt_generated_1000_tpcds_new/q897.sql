WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.s_state,
        cd.cd_education_status,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss,
        cr.cr_return_quantity,
        sr.sr_return_quantity,
        wr.wr_return_quantity,
        i.i_current_price,
        i.i_item_sk,
        inv.inv_quantity_on_hand,
        d_sr.d_year
    FROM
        customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sr.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_wp_creation.d_date_sk
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    s_state,
    cd_education_status,
    SUM(cr_net_loss) AS total_catalog_net_loss,
    SUM(sr_net_loss) AS total_store_net_loss,
    SUM(wr_net_loss) AS total_web_net_loss,
    SUM(cr_return_quantity + sr_return_quantity + wr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT i_item_sk) AS distinct_items_returned,
    MAX(inv_quantity_on_hand) AS max_inventory_on_hand,
    CASE WHEN (SUM(cr_net_loss) + SUM(sr_net_loss) + SUM(wr_net_loss)) > 2000 THEN 'High' ELSE 'Low' END AS loss_category,
    (SUM(cr_net_loss) + SUM(sr_net_loss) + SUM(wr_net_loss)) AS total_net_loss
FROM joined_data
WHERE
    d_year = 2001
    AND i_current_price > 50
    AND s_state = 'CA'
    AND cd_education_status = 'College'
    AND c_customer_sk IN (
        SELECT sr2.sr_customer_sk FROM store_returns sr2 WHERE sr2.sr_return_quantity > 2
        INTERSECT
        SELECT wr2.wr_refunded_customer_sk FROM web_returns wr2 WHERE wr2.wr_return_quantity > 2
    )
    AND c_customer_sk NOT IN (
        SELECT cr4.cr_refunded_customer_sk FROM catalog_returns cr4 WHERE cr4.cr_return_quantity > 5
        EXCEPT
        SELECT sr4.sr_customer_sk FROM store_returns sr4 WHERE sr4.sr_return_quantity = 0
    )
GROUP BY
    c_customer_id,
    c_first_name,
    c_last_name,
    s_state,
    cd_education_status
ORDER BY total_net_loss DESC
OFFSET 0
LIMIT 100

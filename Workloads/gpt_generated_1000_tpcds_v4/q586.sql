WITH
    /* Scalar sub‑query to compute total return loss per order */
    order_return_loss AS (
        SELECT
            cr_order_number,
            SUM(cr_net_loss) AS total_return_loss
        FROM catalog_returns
        GROUP BY cr_order_number
    )
SELECT
    d_sales.d_year                         AS sales_year,
    p_store.p_promo_name                   AS promotion_name,
    s.s_store_name                         AS store_name,
    SUM(ss.ss_net_paid)                    AS total_store_sales,
    SUM(ss.ss_net_profit)                  AS total_store_profit,
    SUM(cs.cs_net_paid_inc_tax)            AS total_catalog_sales,
    SUM(cs.cs_net_profit)                  AS total_catalog_profit,
    SUM(cr.cr_return_amount)               AS total_catalog_return_amount,
    SUM(cr.cr_net_loss)                    AS total_catalog_return_loss,
    SUM(wr.wr_return_amt)                  AS total_web_return_amount,
    SUM(wr.wr_net_loss)                    AS total_web_return_loss,
    /* sum of the scalar sub‑query across the group */
    SUM((SELECT SUM(cr2.cr_net_loss)
         FROM catalog_returns cr2
         WHERE cr2.cr_order_number = cs.cs_order_number)) AS total_order_return_loss,
    COUNT(DISTINCT s.s_store_sk)           AS store_count
FROM
    store_sales ss
    /* date and time for the store sale */
    JOIN date_dim d_sales      ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales      ON ss.ss_sold_time_sk = t_sales.t_time_sk
    /* store information */
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    /* promotion that drove the store sale */
    JOIN promotion p_store     ON ss.ss_promo_sk = p_store.p_promo_sk
    JOIN date_dim d_promo_start ON p_store.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end   ON p_store.p_end_date_sk   = d_promo_end.d_date_sk
    /* catalog sales – linked via the same sales date dimension */
    JOIN catalog_sales cs      ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN date_dim d_ship       ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p_catalog   ON cs.cs_promo_sk = p_catalog.p_promo_sk
    /* catalog returns – linked to catalog sales */
    JOIN catalog_returns cr    ON cr.cr_item_sk = cs.cs_item_sk
                               AND cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_return     ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return     ON cr.cr_returned_time_sk = t_return.t_time_sk
    /* web returns – linked through the sales date dimension */
    JOIN web_returns wr        ON wr.wr_returned_date_sk = d_sales.d_date_sk
    JOIN time_dim t_wr         ON wr.wr_returned_time_sk = t_wr.t_time_sk
    /* web site – linked through the sales date dimension */
    JOIN web_site ws           ON ws.web_open_date_sk = d_sales.d_date_sk
    JOIN date_dim d_ws_close   ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE
    d_sales.d_year BETWEEN 2000 AND 2002
GROUP BY
    d_sales.d_year,
    p_store.p_promo_name,
    s.s_store_name
HAVING
    SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) > 10000
ORDER BY
    total_store_profit DESC
LIMIT 100

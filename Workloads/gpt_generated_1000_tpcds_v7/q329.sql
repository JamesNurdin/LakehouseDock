WITH base AS (
    SELECT
        t.t_time_sk,
        t.t_hour AS hour,
        t.t_meal_time,
        s.s_store_id AS store_id,
        s.s_state,
        s.s_city,
        r.r_reason_desc AS reason_desc,
        cp.cp_department AS department,
        sr.sr_net_loss,
        cr.cr_net_loss
    FROM time_dim t
    JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON s.s_store_sk = sr.sr_store_sk
    JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND s.s_city = 'Los Angeles'
      AND r.r_reason_desc LIKE '%price%'
      AND cp.cp_department = 'Electronics'
      AND t.t_meal_time = 'dinner'
)
SELECT
    store_id,
    reason_desc,
    hour,
    department,
    SUM(sr_net_loss + cr_net_loss) AS total_net_loss,
    (
        SELECT SUM(ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_sold_time_sk = base.t_time_sk
    ) AS total_web_sales_at_time,
    DENSE_RANK() OVER (PARTITION BY reason_desc ORDER BY SUM(sr_net_loss + cr_net_loss) DESC) AS loss_rank_by_reason,
    ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY SUM(sr_net_loss + cr_net_loss) DESC) AS loss_rank_by_store
FROM base
GROUP BY store_id, reason_desc, hour, department, t_time_sk
HAVING SUM(sr_net_loss + cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100

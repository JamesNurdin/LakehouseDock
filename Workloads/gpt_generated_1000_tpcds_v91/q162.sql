WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit AS store_net_profit,
        ss.ss_item_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        sr.sr_ticket_number,
        sr.sr_net_loss AS store_return_loss,
        sr.sr_reason_sk,
        sr.sr_item_sk AS sr_item_sk,
        sr.sr_return_time_sk,
        sr.sr_store_sk AS sr_store_sk,
        i.i_brand,
        i.i_category,
        i.i_product_name,
        t.t_hour,
        s.s_state,
        r.r_reason_desc,
        cr.cr_return_amount,
        cp.cp_department,
        w.w_warehouse_name,
        ws.ws_net_profit AS web_net_profit,
        ws.ws_order_number,
        webs.web_name,
        wr.wr_net_loss AS web_return_loss,
        r2.r_reason_desc AS web_return_reason_desc
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN item i
        ON (CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_item_sk ELSE sr.sr_item_sk END) = i.i_item_sk
    JOIN time_dim t
        ON (CASE WHEN ss.ss_sold_time_sk IS NOT NULL THEN ss.ss_sold_time_sk ELSE sr.sr_return_time_sk END) = t.t_time_sk
    LEFT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
           AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
           AND ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN web_site webs
        ON ws.ws_web_site_sk = webs.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r2
        ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE
        t.t_hour BETWEEN 9 AND 17
        AND s.s_state = 'CA'
        AND ss.ss_net_profit > 0
)
SELECT
    s_state,
    i_brand,
    t_hour,
    SUM(store_net_profit) AS total_store_profit,
    SUM(web_net_profit) AS total_web_profit,
    SUM(store_return_loss) AS total_store_return_loss,
    SUM(web_return_loss) AS total_web_return_loss,
    SUM(cr_return_amount) AS total_catalog_return_amount
FROM joined_data
GROUP BY
    GROUPING SETS (
        (s_state, i_brand, t_hour),
        (s_state, i_brand),
        (s_state, t_hour),
        (i_brand, t_hour),
        (s_state),
        (i_brand),
        (t_hour),
        ()
    )
ORDER BY
    s_state,
    i_brand,
    t_hour
LIMIT 100

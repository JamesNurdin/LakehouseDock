WITH combined_returns AS (
    SELECT
        COALESCE(cr.cr_returned_time_sk, wr.wr_returned_time_sk) AS returned_time_sk,
        COALESCE(cr.cr_return_quantity, 0)               AS cr_return_quantity,
        COALESCE(wr.wr_return_quantity, 0)               AS wr_return_quantity,
        COALESCE(cr.cr_return_amount, 0)                 AS cr_return_amount,
        COALESCE(wr.wr_return_amt, 0)                    AS wr_return_amt,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk    AS cr_reason_sk,
        wr.wr_reason_sk    AS wr_reason_sk,
        cr.cr_refunded_customer_sk,
        wr.wr_refunded_customer_sk,
        cr.cr_refunded_hdemo_sk,
        wr.wr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk,
        wr.wr_refunded_addr_sk,
        cr.cr_item_sk,
        wr.wr_item_sk
    FROM catalog_returns cr
    FULL OUTER JOIN web_returns wr
        ON cr.cr_returned_time_sk = wr.wr_returned_time_sk
        AND cr.cr_item_sk = wr.wr_item_sk
)
SELECT
    td.t_hour,
    s.s_store_name,
    wp.wp_url,
    CASE
        WHEN COALESCE(cr_return_quantity, 0) > 0 THEN 'Catalog'
        WHEN COALESCE(wr_return_quantity, 0) > 0 THEN 'Web'
        ELSE 'None'
    END AS return_channel,
    SUM(ss.ss_ext_sales_price)                                AS total_sales,
    SUM(ss.ss_net_profit)                                    AS total_profit,
    SUM(COALESCE(cr_return_amount, 0) + COALESCE(wr_return_amt, 0)) AS total_return_amount,
    SUM(sr.sr_net_loss)                                      AS total_store_return_loss,
    SUM(ws.ws_ext_sales_price)                               AS total_web_sales,
    COUNT(DISTINCT ss.ss_ticket_number)                      AS distinct_orders,
    AVG(CASE WHEN ss.ss_quantity > 0 THEN ss.ss_sales_price / ss.ss_quantity END) AS avg_price_per_item
FROM combined_returns crw
-- keep every time row (right outer join to time_dim)
RIGHT OUTER JOIN time_dim td
    ON crw.returned_time_sk = td.t_time_sk
-- fact table store_sales joined to the retained time rows (inner)
INNER JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
-- keep stores without sales (right outer join to store dimension)
RIGHT OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
-- additional fact tables and dimensions
LEFT JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN catalog_page cp
    ON crw.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
    ON crw.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN reason r
    ON COALESCE(crw.cr_reason_sk, crw.wr_reason_sk) = r.r_reason_sk
LEFT JOIN customer c
    ON COALESCE(crw.cr_refunded_customer_sk, crw.wr_refunded_customer_sk) = c.c_customer_sk
LEFT JOIN household_demographics hd
    ON COALESCE(crw.cr_refunded_hdemo_sk, crw.wr_refunded_hdemo_sk) = hd.hd_demo_sk
LEFT JOIN customer_address ca
    ON COALESCE(crw.cr_refunded_addr_sk, crw.wr_refunded_addr_sk) = ca.ca_address_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    s.s_state = 'CA'                                            -- filter 1
    AND p.p_discount_active = 'Y'                               -- filter 2
    AND hd.hd_buy_potential = '501-1000'                        -- filter 3
    AND ca.ca_country = 'United States'                         -- filter 4
    AND td.t_hour BETWEEN 8 AND 20                              -- filter 5
    AND cp.cp_department = 'Electronics'                        -- filter 6
GROUP BY
    td.t_hour,
    s.s_store_name,
    wp.wp_url,
    CASE
        WHEN COALESCE(cr_return_quantity, 0) > 0 THEN 'Catalog'
        WHEN COALESCE(wr_return_quantity, 0) > 0 THEN 'Web'
        ELSE 'None'
    END
HAVING
    SUM(ss.ss_ext_sales_price) > 10000
ORDER BY
    total_sales DESC
LIMIT 100

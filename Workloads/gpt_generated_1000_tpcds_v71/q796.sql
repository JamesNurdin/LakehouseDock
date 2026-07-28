WITH joined_data AS (
    SELECT
        wsit.web_site_id,
        wsit.web_name,
        cp.cp_department,
        td_sale.t_hour,
        SUM(ws.ws_net_paid)        AS total_sales,
        SUM(ws.ws_net_profit)     AS total_profit,
        SUM(cr.cr_return_amount)  AS total_returns,
        COUNT(*)                  AS sales_cnt
    FROM web_sales ws
    JOIN time_dim td_sale
        ON ws.ws_sold_time_sk = td_sale.t_time_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN ship_mode sm_ship
        ON ws.ws_ship_mode_sk = sm_ship.sm_ship_mode_sk
    JOIN catalog_returns cr
        ON cr.cr_ship_mode_sk = sm_ship.sm_ship_mode_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td_ret
        ON cr.cr_returned_time_sk = td_ret.t_time_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    WHERE td_sale.t_shift = 'first'
      AND td_ret.t_second IN (10, 15)
      AND cp.cp_department = 'DEPARTMENT'
      AND wsit.web_state = 'CA'
      AND sm_ship.sm_type = 'AIR'
    GROUP BY
        wsit.web_site_id,
        wsit.web_name,
        cp.cp_department,
        td_sale.t_hour
)
SELECT
    web_site_id,
    web_name,
    cp_department,
    t_hour,
    total_sales,
    total_profit,
    total_returns,
    sales_cnt,
    RANK() OVER (PARTITION BY web_site_id ORDER BY total_profit DESC) AS profit_rank
FROM joined_data
ORDER BY total_profit DESC
LIMIT 100

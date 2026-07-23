WITH base AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_category_id,
        i.i_item_desc,
        i.i_current_price,
        cc.cc_call_center_id,
        cc.cc_state,
        cp.cp_department,
        ca_refund.ca_country AS refund_country,
        ca_refund.ca_street_type AS refund_street_type,
        cr.cr_net_loss AS catalog_net_loss,
        sr.sr_net_loss AS store_net_loss,
        ws.ws_net_profit AS web_net_profit,
        t_ws.t_hour AS ws_hour
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return
        ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN customer_address ca_ws_bill
        ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    LEFT JOIN customer_address ca_ws_ship
        ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_category_id IN (1, 2, 3)
      AND ca_refund.ca_country = 'United States'
      AND t_ws.t_hour BETWEEN 8 AND 12
      AND cc.cc_state = 'CA'
)
SELECT
    i_item_id,
    i_category,
    cc_call_center_id,
    cp_department,
    SUM(catalog_net_loss) AS total_catalog_loss,
    SUM(store_net_loss) AS total_store_loss,
    SUM(web_net_profit) AS total_web_profit,
    (SUM(web_net_profit) - (SUM(catalog_net_loss) + SUM(store_net_loss))) AS net_contribution,
    RANK() OVER (PARTITION BY cc_call_center_id ORDER BY (SUM(web_net_profit) - (SUM(catalog_net_loss) + SUM(store_net_loss))) DESC) AS profit_rank
FROM base
GROUP BY
    i_item_id,
    i_category,
    cc_call_center_id,
    cp_department
HAVING
    (SUM(web_net_profit) - (SUM(catalog_net_loss) + SUM(store_net_loss))) > 0
ORDER BY net_contribution DESC
LIMIT 100

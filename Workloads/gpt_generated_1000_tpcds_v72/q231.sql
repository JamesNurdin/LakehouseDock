WITH base AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_page_sk,
        ws.ws_ship_mode_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        i.i_category,
        i.i_brand,
        sm.sm_carrier,
        wp.wp_type,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
agg AS (
    SELECT
        b.i_category,
        b.i_brand,
        b.sm_carrier,
        COUNT(DISTINCT b.ws_order_number) AS order_cnt,
        SUM(b.ws_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_return_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss
    FROM base b
    LEFT JOIN store_returns sr
        ON sr.sr_return_time_sk = b.ws_sold_time_sk
        AND sr.sr_item_sk = b.ws_item_sk
        AND sr.sr_addr_sk = b.ws_bill_addr_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = b.ws_sold_time_sk
        AND cr.cr_item_sk = b.ws_item_sk
        AND cr.cr_refunded_addr_sk = b.ws_bill_addr_sk
        AND cr.cr_ship_mode_sk = b.ws_ship_mode_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = b.ws_sold_time_sk
        AND wr.wr_item_sk = b.ws_item_sk
        AND wr.wr_refunded_addr_sk = b.ws_bill_addr_sk
        AND wr.wr_web_page_sk = b.ws_web_page_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE b.ws_quantity > (
        SELECT AVG(ws_quantity)
        FROM web_sales
        WHERE ws_sold_date_sk = b.ws_sold_date_sk
    )
    GROUP BY b.i_category, b.i_brand, b.sm_carrier
    HAVING SUM(b.ws_ext_sales_price) > 10000
)
SELECT
    i_category,
    i_brand,
    sm_carrier,
    order_cnt,
    total_sales,
    store_return_loss,
    catalog_return_loss,
    web_return_loss,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS category_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100

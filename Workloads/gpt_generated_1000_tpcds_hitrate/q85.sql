WITH base AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        s.s_store_id,
        web.web_name,
        sr.sr_net_loss,
        ws.ws_net_profit,
        sr.sr_ticket_number,
        ws.ws_sales_price,
        d_sr.d_date
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_sr.d_date_sk
    JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_order_number = wr.wr_order_number
                     AND ws.ws_item_sk = i.i_item_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                       AND inv.inv_date_sk = d_sr.d_date_sk
    WHERE
        d_sr.d_year = 2001
        AND s.s_state = 'CA'
        AND i.i_brand_id = 12
        AND wh.w_city = 'Seattle'
        AND web.web_company_name = 'anti'
        AND NOT EXISTS (
            SELECT 1
            FROM inventory inv2
            WHERE inv2.inv_item_sk = i.i_item_sk
              AND inv2.inv_date_sk = d_sr.d_date_sk
              AND inv2.inv_quantity_on_hand = 0
        )
)
SELECT
    i_item_id,
    i_product_name,
    s_store_id,
    web_name,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT sr_ticket_number) AS store_return_cnt,
    AVG(ws_sales_price) AS avg_sales_price,
    MIN(d_date) AS first_return_date,
    MAX(d_date) AS last_return_date
FROM base
GROUP BY
    i_item_id,
    i_product_name,
    s_store_id,
    web_name
ORDER BY
    total_store_return_loss DESC
LIMIT 100

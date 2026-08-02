WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_tax_percentage,
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        inv.inv_quantity_on_hand,
        cp.cp_type,
        r.r_reason_desc,
        hd.hd_vehicle_count,
        ca.ca_state,
        ws.ws_sales_price,
        ws.ws_ext_sales_price
    FROM date_dim d
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
       AND cr.cr_item_sk = i.i_item_sk
       AND cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 1998
      AND i.i_current_price > 100
      AND s.s_tax_percentage > 5
      AND cp.cp_type = 'monthly'
      AND r.r_reason_desc LIKE '%Damaged%'
      AND hd.hd_vehicle_count >= 2
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    d_month_seq,
    i_item_id,
    i_brand,
    i_category,
    SUM(sr_return_quantity) AS total_return_qty,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(cr_return_quantity) AS total_catalog_return_qty,
    SUM(cr_net_loss) AS total_catalog_return_loss,
    COALESCE(SUM(sr_net_loss) + SUM(cr_net_loss), 0) AS total_net_loss,
    AVG(inv_quantity_on_hand) AS avg_inventory_qty,
    MAX(ws_ext_sales_price) AS max_ws_ext_sales_price,
    RANK() OVER (PARTITION BY d_year ORDER BY COALESCE(SUM(sr_net_loss) + SUM(cr_net_loss), 0) DESC) AS loss_rank,
    (SELECT AVG(ws2.ws_sales_price)
       FROM web_sales ws2
       WHERE ws2.ws_item_sk = base.i_item_sk
         AND ws2.ws_sold_date_sk = base.d_date_sk) AS avg_item_sales_price,
    ws_top.ws_order_number,
    ws_top.top_ws_ext_sales_price
FROM base
LEFT JOIN LATERAL (
    SELECT ws2.ws_order_number,
           ws2.ws_ext_sales_price AS top_ws_ext_sales_price
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = base.i_item_sk
      AND ws2.ws_sold_date_sk = base.d_date_sk
    ORDER BY ws2.ws_ext_sales_price DESC
    LIMIT 1
) ws_top ON TRUE
GROUP BY
    s_store_id,
    s_store_name,
    d_year,
    d_month_seq,
    i_item_id,
    i_brand,
    i_category,
    i_item_sk,
    d_date_sk,
    ws_top.ws_order_number,
    ws_top.top_ws_ext_sales_price
ORDER BY total_net_loss DESC, loss_rank ASC
LIMIT 100

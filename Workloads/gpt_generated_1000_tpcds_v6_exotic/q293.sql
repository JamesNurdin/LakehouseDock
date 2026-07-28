WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        cr.cr_return_amount,
        cr.cr_fee,
        c.c_customer_id,
        c.c_customer_sk,
        cp.cp_department,
        r.r_reason_desc,
        s.s_store_name,
        wsite.web_name,
        wp.wp_url,
        d.d_year,
        t.t_shift,
        inv.inv_quantity_on_hand
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_order_number = ws.ws_order_number
        AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND t.t_shift = 'first'
      AND ws.ws_net_profit > 0
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    s_store_name,
    web_name,
    d_year,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(inv_quantity_on_hand) AS avg_inventory_qty,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    (
        SELECT COUNT(DISTINCT cr2.cr_reason_sk)
        FROM catalog_returns cr2
        JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        JOIN store s2 ON s2.s_closed_date_sk = d2.d_date_sk
        WHERE s2.s_store_name = s_store_name
          AND d2.d_year = d_year
    ) AS distinct_return_reasons
FROM base
GROUP BY s_store_name, web_name, d_year
HAVING SUM(ws_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100

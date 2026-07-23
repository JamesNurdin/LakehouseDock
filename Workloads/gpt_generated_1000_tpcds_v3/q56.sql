WITH base AS (
    SELECT
        d.d_year,
        i.i_brand,
        sm.sm_code,
        ca.ca_state,
        p.p_promo_name,
        p.p_discount_active,
        wp.wp_type,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_ship_cost,
        cr.cr_net_loss,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_ship_cost,
        sr.sr_net_loss,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_quantity
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = cs.cs_item_sk
    JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
    JOIN customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
)
SELECT
    d_year,
    i_brand,
    sm_code,
    ca_state,
    p_promo_name,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cs_net_paid) + SUM(ws_net_paid) AS total_sales,
    SUM(cr_return_amount) + SUM(sr_return_amt) AS total_returns,
    SUM(cs_net_profit) + SUM(ws_net_profit) - SUM(cr_net_loss) - SUM(sr_net_loss) AS net_total_profit,
    COUNT(DISTINCT cs_order_number) + COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(cs_ext_discount_amt) + SUM(ws_ext_discount_amt) AS total_discount,
    CASE
        WHEN (SUM(cs_net_profit) + SUM(ws_net_profit) - SUM(cr_net_loss) - SUM(sr_net_loss)) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_flag
FROM base
WHERE
    i_brand = 'Brand#12'
    AND sm_code = 'AIR'
    AND ca_state = 'CA'
    AND d_year = 2001
    AND p_discount_active = 'Y'
    AND wp_type = 'Content'
GROUP BY
    d_year,
    i_brand,
    sm_code,
    ca_state,
    p_promo_name
HAVING
    (SUM(cs_net_paid) + SUM(ws_net_paid)) > 100000
    AND (COUNT(DISTINCT cs_order_number) + COUNT(DISTINCT ws_order_number)) > 10
ORDER BY
    total_sales DESC
LIMIT 100

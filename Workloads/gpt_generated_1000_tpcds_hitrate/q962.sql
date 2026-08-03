WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_promo_sk,
        ws.ws_web_site_sk,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        td.t_hour,
        i.i_category,
        i.i_class_id,
        ca.ca_state,
        ca.ca_country,
        hd.hd_income_band_sk,
        p.p_promo_name,
        p.p_discount_active,
        wr.wr_reason_sk,
        r.r_reason_desc
    FROM
        web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
        i.i_class_id = 2
        AND hd.hd_income_band_sk = 18
        AND ca.ca_country = 'United States'
        AND td.t_hour BETWEEN 12 AND 14
        AND EXISTS (
            SELECT 1
            FROM web_returns wr2
            WHERE wr2.wr_order_number = ws.ws_order_number
              AND wr2.wr_return_quantity > 0
        )
)
SELECT
    i_category,
    ca_state,
    t_hour,
    p_promo_name,
    SUM(ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    AVG(ws_ext_discount_amt) AS avg_discount_amt,
    SUM(CASE WHEN p_discount_active = 'Y' THEN ws_ext_discount_amt ELSE 0 END) AS promo_discount_sum,
    ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid) DESC) AS rn
FROM
    filtered_sales
GROUP BY
    i_category,
    ca_state,
    t_hour,
    p_promo_name,
    p_discount_active
ORDER BY
    total_net_paid DESC
LIMIT 100

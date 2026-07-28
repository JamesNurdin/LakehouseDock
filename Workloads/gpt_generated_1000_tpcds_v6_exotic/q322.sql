WITH joined_data AS (
    SELECT
        ws.ws_order_number,
        d_sold.d_date,
        d_sold.d_year,
        t.t_time,
        t.t_shift,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        ws.ws_quantity,
        ws.ws_net_profit,
        p.p_promo_name,
        p.p_discount_active,
        wp.wp_url,
        wp.wp_type,
        ca.ca_city,
        ca.ca_state
    FROM
        web_sales ws
        INNER JOIN date_dim d_sold
            ON ws.ws_sold_date_sk = d_sold.d_date_sk
        INNER JOIN time_dim t
            ON ws.ws_sold_time_sk = t.t_time_sk
        INNER JOIN item i
            ON ws.ws_item_sk = i.i_item_sk
        INNER JOIN customer_address ca
            ON ws.ws_bill_addr_sk = ca.ca_address_sk
        INNER JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
        INNER JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        INNER JOIN date_dim d_ship
            ON ws.ws_ship_date_sk = d_ship.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND t.t_shift = 'first'
        AND i.i_brand = 'Brand#23'
        AND p.p_discount_active = 'Y'
        AND wp.wp_type = 'typeA'
)
SELECT
    jd.ws_order_number,
    jd.d_date,
    jd.d_year,
    jd.t_time,
    jd.t_shift,
    jd.i_item_id,
    jd.i_brand,
    jd.i_category,
    jd.ws_quantity,
    jd.ws_net_profit,
    jd.p_promo_name,
    jd.wp_url,
    jd.ca_city,
    jd.ca_state,
    RANK() OVER (PARTITION BY jd.d_year, jd.i_brand ORDER BY jd.ws_net_profit DESC) AS profit_rank
FROM
    joined_data jd
ORDER BY
    profit_rank,
    jd.ws_net_profit DESC
LIMIT 100

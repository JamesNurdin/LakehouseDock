WITH filtered AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_net_loss,
        ws.ws_order_number,
        ws.ws_net_profit,
        i.i_brand,
        i.i_class,
        i.i_item_desc,
        p.p_promo_name
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE
        regexp_like(i.i_item_desc, '^.*BRIGHT.*$')
        AND ca.ca_state LIKE 'C%'
        AND regexp_extract(p.p_promo_name, '(\\d+)%', 1) IS NOT NULL
)
SELECT
    d.d_year,
    d.d_moy,
    concat(f.i_brand, ' ', f.i_class) AS brand_class,
    regexp_extract(f.p_promo_name, '(\\d+)%', 1) AS discount_pct,
    sum(f.wr_net_loss) AS total_return_net_loss,
    sum(f.ws_net_profit) AS total_sales_profit
FROM filtered f
JOIN date_dim d
    ON f.wr_returned_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    d.d_moy,
    f.i_brand,
    f.i_class,
    regexp_extract(f.p_promo_name, '(\\d+)%', 1)
ORDER BY
    d.d_year DESC,
    d.d_moy DESC,
    total_return_net_loss DESC
LIMIT 100

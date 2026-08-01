WITH promo_sales AS (
    -- Right outer join keeps promotions with no sales
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_web_page_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk
    FROM promotion p
    RIGHT OUTER JOIN web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
)
SELECT
    cc.cc_state,
    d_sales.d_year,
    ps.p_promo_name,
    SUM(ps.ws_ext_sales_price)                         AS total_sales,
    SUM(COALESCE(sr.sr_return_amt, 0))                  AS total_returns,
    SUM(ps.ws_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_contrib,
    CASE WHEN SUM(ps.ws_ext_sales_price) > 0 THEN 'HAS_SALES' ELSE 'NO_SALES' END AS sales_flag,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY SUM(ps.ws_ext_sales_price) DESC) AS sales_rank,
    (
        SELECT AVG(ws2.ws_ext_discount_amt)
        FROM web_sales ws2
        WHERE ws2.ws_quantity > 0
    )                                                  AS avg_discount_overall
FROM
    promo_sales ps
    -- join promotion again to have an extra join clause (different role)
    JOIN promotion p ON ps.p_promo_sk = p.p_promo_sk
    -- date dimension for the sales date
    JOIN date_dim d_sales ON ps.ws_sold_date_sk = d_sales.d_date_sk
    -- item dimension
    JOIN item i ON ps.ws_item_sk = i.i_item_sk
    -- billing customer dimension
    JOIN customer c ON ps.ws_bill_customer_sk = c.c_customer_sk
    -- household demographics via current hd key on the customer
    JOIN household_demographics hh ON c.c_current_hdemo_sk = hh.hd_demo_sk
    -- web page dimension
    JOIN web_page wp ON ps.ws_web_page_sk = wp.wp_web_page_sk
    -- keep call‑center rows (right side retained) – joined through the sales date
    LEFT JOIN call_center cc ON d_sales.d_date_sk = cc.cc_open_date_sk
    -- possible returns for the same item/customer
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                                AND sr.sr_customer_sk = c.c_customer_sk
    -- date dimension for the return date (second alias)
    LEFT JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    -- reason dimension for returns
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE
    -- keep only items with a relatively high price (IN subquery)
    i.i_item_id IN (
        SELECT i_item_id FROM item WHERE i_current_price > 100
    )
    -- promotion must satisfy a combination of INTERSECT and EXCEPT
    AND p.p_promo_sk IN (
        SELECT p_promo_sk FROM promotion WHERE p_discount_active = 'Y'
        INTERSECT
        SELECT ws_promo_sk FROM web_sales WHERE ws_quantity > 0
        EXCEPT
        SELECT ws_promo_sk FROM web_sales WHERE ws_ext_discount_amt > 500
    )
    -- anti‑join: exclude customers who already have a return on the sales date for the same item
    AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_returned_date_sk = d_sales.d_date_sk
    )
GROUP BY
    ROLLUP (cc.cc_state, d_sales.d_year, ps.p_promo_name)
ORDER BY
    cc.cc_state,
    d_sales.d_year,
    total_sales DESC
LIMIT 100

WITH sales AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)   -- sample 10% of catalog_sales
    ),
    orders_without_return AS (
        SELECT cs_order_number
        FROM sales
        EXCEPT
        SELECT cr_order_number
        FROM catalog_returns
    ),
    cr_sr AS (
        SELECT
            cr.cr_order_number,
            cr.cr_item_sk,
            cr.cr_return_amount,
            sr.sr_ticket_number,
            sr.sr_return_amt,
            sr.sr_return_quantity
        FROM catalog_returns cr
        FULL OUTER JOIN store_returns sr
            ON cr.cr_item_sk = sr.sr_item_sk   -- valid join key
    )
SELECT
    s.cs_order_number,
    s.cs_sold_date_sk,
    i.i_item_id,
    i.i_category,
    p.p_promo_name,
    sm.sm_type,
    cd_bill.cd_gender      AS bill_gender,
    cd_ship.cd_gender      AS ship_gender,
    w.ws_quantity          AS web_quantity,
    wp.wp_type             AS web_page_type,
    ws.web_name            AS web_site_name,
    cr_sr.cr_return_amount,
    cr_sr.sr_return_amt,
    cr_sr.sr_return_quantity,
    (
        SELECT SUM(sr2.sr_return_quantity)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
    ) AS total_store_return_qty,
    ROW_NUMBER() OVER (ORDER BY s.cs_order_number) AS rn
FROM sales s
JOIN item i
    ON s.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON s.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd_bill
    ON s.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON s.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN web_sales w
    ON w.ws_item_sk = i.i_item_sk
   AND w.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN web_page wp
    ON w.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site ws
    ON w.ws_web_site_sk = ws.web_site_sk
LEFT JOIN cr_sr
    ON cr_sr.cr_order_number = s.cs_order_number
WHERE s.cs_order_number IN (SELECT cs_order_number FROM orders_without_return)
ORDER BY s.cs_order_number
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

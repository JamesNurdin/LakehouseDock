/*
Goal: Identify the top‑10 net‑paid sales rows per California store for high‑price items shipped overnight, excluding items that have any large web return (> $500). The result is ranked by net paid amount within each store.
*/
WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        i.i_item_id,
        i.i_product_name,
        s.s_store_name,
        p.p_promo_name,
        sm.sm_type,
        cr.cr_return_amount,
        wr.wr_return_amt,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_net_paid DESC) AS sales_rank
    FROM store_sales ss
    JOIN item i                ON ss.ss_item_sk = i.i_item_sk
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr    ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm          ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr       ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20
      AND sm.sm_type = 'OVERNIGHT'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cr.cr_return_amount > 100
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_item_sk = i.i_item_sk
            AND wr2.wr_return_amt > 500
      )
)
SELECT
    ss_ticket_number,
    ss_sold_date_sk,
    i_item_id,
    i_product_name,
    s_store_name,
    p_promo_name,
    sm_type,
    cr_return_amount,
    wr_return_amt,
    ss_net_paid,
    ss_net_profit,
    sales_rank
FROM joined_data
WHERE sales_rank <= 10
ORDER BY s_store_name, sales_rank
LIMIT 100
